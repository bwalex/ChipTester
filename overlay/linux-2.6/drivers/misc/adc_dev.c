#include <asm/irq.h>
#include <asm/io.h>
#include <asm/uaccess.h>
#include <linux/types.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/kernel.h>
#include <linux/signal.h>
#include <linux/sched.h>
#include <linux/interrupt.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/poll.h>


#define DRIVER_NAME	"adc"
#define MAX_CDEVS	8


#define MAJOR_NUM		0xFB
#define ADC_IOC_ENABLE		_IO(MAJOR_NUM, 0)
#define ADC_IOC_GET_DONE	_IOR(MAJOR_NUM, 1, uint8_t)
#define ADC_IOC_GET_MAGIC	_IOR(MAJOR_NUM, 2, uint8_t)

#define ADC_IRQ_REG		0x0A
#define ADC_MAGIC_REG		0x0F
#define ADC_DONE_REG		0xA0
#define ADC_ENABLE_REG		0xB0

#define ADC_MAGIC		0x0a


struct adc_softc {
	struct cdev	ad_cdev;
	wait_queue_head_t	ad_wq;
	int		ad_busy;
	int		ad_id;
	int		ad_irq;
	uint8_t		*ad_base;
};


static dev_t adc_dev;
static int adc_major;
static struct class *adc_class;


static uint8_t
adc_read_reg(struct adc_softc *sc, int reg)
{
	return readb(sc->ad_base + reg);
}


static void
adc_write_reg(struct adc_softc *sc, int reg, uint8_t v)
{
	writeb(v, sc->ad_base + reg);
}


static int
adc_get_done(struct adc_softc *sc)
{
	uint8_t d;

	d = adc_read_reg(sc, ADC_DONE_REG);

	return (int)d;
}


static int
adc_enable(struct adc_softc *sc)
{
	uint8_t e = 1;
	int rc;


	if (sc->ad_busy)
		return -EBUSY;

	rc = adc_get_done(sc);
	if (!rc)
		return -EBUSY;

	sc->ad_busy = 1;
	adc_write_reg(sc, ADC_ENABLE_REG, e);

	return 0;
}


static int
adc_check_magic(struct adc_softc *sc)
{
	uint8_t d;

	d = adc_read_reg(sc, ADC_MAGIC_REG);

	return (d != ADC_MAGIC) ? ENODEV : 0;
}



static int
adc_open(struct inode *inode, struct file *file)
{
	try_module_get(THIS_MODULE);

	return 0;
}


static int
adc_release(struct inode *inode, struct file *file)
{
	module_put(THIS_MODULE);

	return 0;
}


static long
adc_ioctl(struct file *file,
	      unsigned int cmd, unsigned long param)
{
	struct adc_softc *sc;
	uint8_t d;
	int rc = 0;

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct adc_softc, ad_cdev);

	switch (cmd) {
	case ADC_IOC_ENABLE:
		rc = adc_enable(sc);
		break;


	case ADC_IOC_GET_DONE:
		if (!access_ok(VERIFY_WRITE, (void *)param, sizeof(uint8_t)))
			return -ENOTTY;

		d = adc_read_reg(sc, ADC_DONE_REG);
		put_user(d, (uint8_t *)param);
		break;


	case ADC_IOC_GET_MAGIC:
		if (!access_ok(VERIFY_WRITE, (void *)param, sizeof(uint8_t)))
			return -ENOTTY;

		d = adc_read_reg(sc, ADC_MAGIC_REG);
		put_user(d, (uint8_t *)param);
		break;


	default:
		return -ENOTTY;
	}

	return rc;
}


static unsigned int
adc_poll(struct file *file, struct poll_table_struct *pts)
{
	struct adc_softc *sc;
	unsigned int mask = 0;

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct adc_softc, ad_cdev);

	poll_wait(file, &sc->ad_wq, pts);

	if (!sc->ad_busy)
		mask |= POLLIN | POLLRDNORM;

	return mask;
}


static struct file_operations adc_fops = {
	.owner		= THIS_MODULE,
	.open		= adc_open,
	.poll		= adc_poll,
	.unlocked_ioctl	= adc_ioctl,
	.release	= adc_release,

};


static irqreturn_t
adc_irq_handler(int irq, void *priv)
{
	struct device *dev = priv;
	struct adc_softc *sc = dev->platform_data;
	uint8_t irqs;

	/* XXX: temporary debug */
	dev_info(dev, "adc_irq\n");

	/* Reading the IRQ register clears the interrupt(s) */
	irqs = adc_read_reg(sc, ADC_IRQ_REG);

	sc->ad_busy = 0;

	wake_up(&sc->ad_wq);

	return IRQ_HANDLED;
}


static int __devinit
adc_probe(struct platform_device *pdev)
{
	struct adc_softc sc, *scp;
	struct resource *res_mem;
	void *ad_base;
	int id, irq;
	int rc;

	irq = -1;
	ad_base = NULL;

	id = (pdev->id >= 0) ? pdev->id : 0;

	irq = platform_get_irq(pdev, 0);
	if (irq == ENXIO)
		return -ENODEV;

	res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (res_mem == NULL) {
		dev_err(&pdev->dev, "platform_get_resource failed!\n");
		return -ENODEV;
	}

	ad_base = ioremap(res_mem->start, resource_size(res_mem));
	if (ad_base == NULL) {
		dev_err(&pdev->dev, "ioremap failed!\n");
		return -ENODEV;
	}

	sc.ad_busy = 0;
	sc.ad_id = id;
	sc.ad_irq = irq;
	sc.ad_base = ad_base;

	rc = adc_check_magic(&sc);
	if (rc) {
		dev_err(&pdev->dev, "magic number mismatch!\n");
		goto error;
	}

	rc = platform_device_add_data(pdev, &sc, sizeof(sc));
	if (rc) {
		dev_err(&pdev->dev, "platform_device_add_data failed!\n");
		goto error;
	}

	scp = pdev->dev.platform_data;
	init_waitqueue_head(&scp->ad_wq);

	rc = request_irq(irq, adc_irq_handler, 0 /* flags */, DRIVER_NAME,
			 &pdev->dev);
	if (rc) {
		dev_err(&pdev->dev, "request_irq failed!\n");
		goto error;
	}

	cdev_init(&scp->ad_cdev, &adc_fops);
	kobject_set_name(&scp->ad_cdev.kobj, "%s%d", DRIVER_NAME, id);

	rc = cdev_add(&scp->ad_cdev, MKDEV(adc_major, id), 1);
	if (rc) {
		dev_err(&pdev->dev, "cdev_add failed!\n");
		kobject_put(&scp->ad_cdev.kobj);
		goto error;
	}

	if (IS_ERR(device_create(adc_class, &pdev->dev,
				MKDEV(adc_major, id), NULL,
				"%s%d", DRIVER_NAME, id))) {
		dev_err(&pdev->dev, "device_create failed!\n");
		cdev_del(&scp->ad_cdev);
		goto error;
	}

	dev_info(&pdev->dev, "ADC device %d, irq %d\n", id, irq);

	return 0;


error:
	if (irq >= 0)
		free_irq(irq, &pdev->dev);
	if (ad_base)
		iounmap(ad_base);

	return -ENODEV;
}


static int __devexit
adc_remove(struct platform_device *pdev)
{
	struct adc_softc *sc = pdev->dev.platform_data;

	device_destroy(adc_class, MKDEV(adc_major, sc->ad_id));
	cdev_del(&sc->ad_cdev);
	free_irq(sc->ad_irq, &pdev->dev);
	iounmap(sc->ad_base);

	return 0;
}


#ifdef CONFIG_OF
static struct of_device_id adc_match[] = {
	{ .compatible = "adc,adc-1.0", },
	{}
};
MODULE_DEVICE_TABLE(of, adc_match);
#endif /* CONFIG_OF */

static struct platform_driver adc_platform_driver = {
	.probe = adc_probe,
	.remove = __devexit_p(adc_remove),
	.driver = {
		.name		= DRIVER_NAME,
		.owner		= THIS_MODULE,
#ifdef CONFIG_OF
		.of_match_table	= of_match_ptr(adc_match),
#endif
	},
};


static int __init
adc_init(void)
{
	int rc;

	printk(KERN_INFO "ADC Module loaded\n");

	adc_class = class_create(THIS_MODULE, "adc");
	if (IS_ERR(adc_class)) {
		rc = PTR_ERR(adc_class);
		printk(KERN_ERR "adc: class_create failed!\n");
		return rc;
	}

	rc = alloc_chrdev_region(&adc_dev, 0, MAX_CDEVS, DRIVER_NAME);
	if (rc) {
		printk(KERN_ERR "adc: alloc_chrdev_region failed!\n");
		class_destroy(adc_class);
		return rc;
	}

	adc_major = MAJOR(adc_dev);

	rc = platform_driver_register(&adc_platform_driver);

	return rc;
}


static void __exit
adc_exit(void)
{
	printk(KERN_INFO "ADC Module unloaded\n");

	platform_driver_unregister(&adc_platform_driver);

	unregister_chrdev_region(adc_dev, MAX_CDEVS);

	class_destroy(adc_class);
}


module_init(adc_init);
module_exit(adc_exit);


MODULE_LICENSE("GPL");
MODULE_AUTHOR("Alex Hornung <alex@alexhornung.com>");
MODULE_DESCRIPTION("Driver for the ADC module");
MODULE_SUPPORTED_DEVICE(DRIVER_NAME);
