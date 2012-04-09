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


#define DRIVER_NAME	"trunner"
#define MAX_CDEVS	8


#define MAJOR_NUM		0xFE
#define TRUNNER_IOC_ENABLE	_IO(MAJOR_NUM, 0)
#define TRUNNER_IOC_GET_DONE	_IOR(MAJOR_NUM, 1, uint8_t)
#define TRUNNER_IOC_GET_MAGIC	_IOR(MAJOR_NUM, 2, uint8_t)

#define TRUNNER_IRQ_REG			0x0a
#define TRUNNER_MAGIC_REG		0x7f
#define TRUNNER_DONE_REG		0x80
#define TRUNNER_ENABLE_REG		0x81

#define TRUNNER_MAGIC			0x0a


struct trunner_softc {
	struct cdev	tr_cdev;
	wait_queue_head_t	tr_wq;
	int		tr_busy;
	int		tr_id;
	int		tr_irq;
	uint8_t		*tr_base;
};


static dev_t trunner_dev;
static int trunner_major;
static struct class *trunner_class;


static uint8_t
trunner_read_reg(struct trunner_softc *sc, int reg)
{
	return readb(sc->tr_base + reg);
}


static void
trunner_write_reg(struct trunner_softc *sc, int reg, uint8_t v)
{
	writeb(v, sc->tr_base + reg);
}


static int
trunner_get_done(struct trunner_softc *sc)
{
	uint8_t d;

	d = trunner_read_reg(sc, TRUNNER_DONE_REG);

	return (int)d;
}


static int
trunner_enable(struct trunner_softc *sc)
{
	uint8_t e = 1;
	int rc;


	if (sc->tr_busy)
		return -EBUSY;

	rc = trunner_get_done(sc);
	if (!rc)
		return -EBUSY;

	sc->tr_busy = 1;
	trunner_write_reg(sc, TRUNNER_ENABLE_REG, e);

	return 0;
}


static int
trunner_check_magic(struct trunner_softc *sc)
{
	uint8_t d;

	d = trunner_read_reg(sc, TRUNNER_MAGIC_REG);

	return (d != TRUNNER_MAGIC) ? ENODEV : 0;
}



static int
trunner_open(struct inode *inode, struct file *file)
{
	try_module_get(THIS_MODULE);

	return 0;
}


static int
trunner_release(struct inode *inode, struct file *file)
{
	module_put(THIS_MODULE);

	return 0;
}


static long
trunner_ioctl(struct file *file,
	      unsigned int cmd, unsigned long param)
{
	struct trunner_softc *sc;
	uint8_t d;
	int rc = 0;

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct trunner_softc, tr_cdev);

	switch (cmd) {
	case TRUNNER_IOC_ENABLE:
		rc = trunner_enable(sc);
		break;


	case TRUNNER_IOC_GET_DONE:
		if (!access_ok(VERIFY_WRITE, (void *)param, sizeof(uint8_t)))
			return -ENOTTY;

		d = trunner_read_reg(sc, TRUNNER_DONE_REG);
		put_user(d, (uint8_t *)param);
		break;


	case TRUNNER_IOC_GET_MAGIC:
		if (!access_ok(VERIFY_WRITE, (void *)param, sizeof(uint8_t)))
			return -ENOTTY;

		d = trunner_read_reg(sc, TRUNNER_MAGIC_REG);
		put_user(d, (uint8_t *)param);
		break;


	default:
		return -ENOTTY;
	}

	return rc;
}


static unsigned int
trunner_poll(struct file *file, struct poll_table_struct *pts)
{
	struct trunner_softc *sc;
	unsigned int mask = 0;

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct trunner_softc, tr_cdev);

	poll_wait(file, &sc->tr_wq, pts);

	if (!sc->tr_busy)
		mask |= POLLIN | POLLRDNORM;

	return mask;
}


static struct file_operations trunner_fops = {
	.owner		= THIS_MODULE,
	.open		= trunner_open,
	.poll		= trunner_poll,
	.unlocked_ioctl	= trunner_ioctl,
	.release	= trunner_release,

};


static irqreturn_t
trunner_irq_handler(int irq, void *priv)
{
	struct device *dev = priv;
	struct trunner_softc *sc = dev->platform_data;
	uint8_t irqs;

	/* XXX: temporary debug */
	dev_info(dev, "trunner_irq\n");

	/* Reading the IRQ register clears the interrupt(s) */
	irqs = trunner_read_reg(sc, TRUNNER_IRQ_REG);

	sc->tr_busy = 0;

	wake_up(&sc->tr_wq);

	return IRQ_HANDLED;
}


static int __devinit
trunner_probe(struct platform_device *pdev)
{
	struct trunner_softc sc, *scp;
	struct resource *res_mem;
	void *tr_base;
	int id, irq;
	int rc;

	irq = -1;
	tr_base = NULL;

	id = (pdev->id >= 0) ? pdev->id : 0;

	irq = platform_get_irq(pdev, 0);
	if (irq == ENXIO)
		return -ENODEV;

	res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (res_mem == NULL) {
		dev_err(&pdev->dev, "platform_get_resource failed!\n");
		return -ENODEV;
	}

	tr_base = ioremap(res_mem->start, resource_size(res_mem));
	if (tr_base == NULL) {
		dev_err(&pdev->dev, "ioremap failed!\n");
		return -ENODEV;
	}

	sc.tr_busy = 0;
	sc.tr_id = id;
	sc.tr_irq = irq;
	sc.tr_base = tr_base;

	rc = trunner_check_magic(&sc);
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
	init_waitqueue_head(&scp->tr_wq);

	rc = request_irq(irq, trunner_irq_handler, 0 /* flags */, DRIVER_NAME,
			 &pdev->dev);
	if (rc) {
		dev_err(&pdev->dev, "request_irq failed!\n");
		goto error;
	}

	cdev_init(&scp->tr_cdev, &trunner_fops);
	kobject_set_name(&scp->tr_cdev.kobj, "%s%d", DRIVER_NAME, id);

	rc = cdev_add(&scp->tr_cdev, MKDEV(trunner_major, id), 1);
	if (rc) {
		dev_err(&pdev->dev, "cdev_add failed!\n");
		kobject_put(&scp->tr_cdev.kobj);
		goto error;
	}

	if (IS_ERR(device_create(trunner_class, &pdev->dev,
				MKDEV(trunner_major, id), NULL,
				"%s%d", DRIVER_NAME, id))) {
		dev_err(&pdev->dev, "device_create failed!\n");
		cdev_del(&scp->tr_cdev);
		goto error;
	}

	dev_info(&pdev->dev, "Test Runner device %d, irq %d\n", id, irq);

	return 0;


error:
	if (irq >= 0)
		free_irq(irq, &pdev->dev);
	if (tr_base)
		iounmap(tr_base);

	return -ENODEV;
}


static int __devexit
trunner_remove(struct platform_device *pdev)
{
	struct trunner_softc *sc = pdev->dev.platform_data;

	device_destroy(trunner_class, MKDEV(trunner_major, sc->tr_id));
	cdev_del(&sc->tr_cdev);
	free_irq(sc->tr_irq, &pdev->dev);
	iounmap(sc->tr_base);

	return 0;
}


#ifdef CONFIG_OF
static struct of_device_id trunner_match[] = {
	{ .compatible = "trunner,trunner-1.0", },
	{}
};
MODULE_DEVICE_TABLE(of, trunner_match);
#endif /* CONFIG_OF */

static struct platform_driver trunner_platform_driver = {
	.probe = trunner_probe,
	.remove = __devexit_p(trunner_remove),
	.driver = {
		.name		= DRIVER_NAME,
		.owner		= THIS_MODULE,
#ifdef CONFIG_OF
		.of_match_table	= of_match_ptr(trunner_match),
#endif
	},
};


static int __init
trunner_init(void)
{
	int rc;

	printk(KERN_INFO "Test Runner Module loaded\n");

	trunner_class = class_create(THIS_MODULE, "trunner");
	if (IS_ERR(trunner_class)) {
		rc = PTR_ERR(trunner_class);
		printk(KERN_ERR "trunner: class_create failed!\n");
		return rc;
	}

	rc = alloc_chrdev_region(&trunner_dev, 0, MAX_CDEVS, DRIVER_NAME);
	if (rc) {
		printk(KERN_ERR "trunner: alloc_chrdev_region failed!\n");
		class_destroy(trunner_class);
		return rc;
	}

	trunner_major = MAJOR(trunner_dev);

	rc = platform_driver_register(&trunner_platform_driver);

	return rc;
}


static void __exit
trunner_exit(void)
{
	printk(KERN_INFO "Test Runner Module unloaded\n");

	platform_driver_unregister(&trunner_platform_driver);

	unregister_chrdev_region(trunner_dev, MAX_CDEVS);

	class_destroy(trunner_class);
}


module_init(trunner_init);
module_exit(trunner_exit);


MODULE_LICENSE("GPL");
MODULE_AUTHOR("Alex Hornung <alex@alexhornung.com>");
MODULE_DESCRIPTION("Driver for the test runner module");
MODULE_SUPPORTED_DEVICE(DRIVER_NAME);
