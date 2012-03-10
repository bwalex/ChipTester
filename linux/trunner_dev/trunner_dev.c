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
	printk(KERN_INFO "trunner_probe called, id=%d\n", id);

	irq = platform_get_irq(pdev, 0);
	if (irq == ENXIO)
		return -ENODEV;

	printk(KERN_INFO "trunner irq: %d\n", irq);

	res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (res_mem == NULL)
		return -ENODEV;


	tr_base = ioremap(res_mem->start, resource_size(res_mem));
	if (tr_base == NULL) {
		printk(KERN_ERR "trunner could not ioremap\n");
		return -ENODEV;
	}


	sc.tr_busy = 0;
	sc.tr_id = id;
	sc.tr_irq = irq;
	sc.tr_base = tr_base;
	init_waitqueue_head(&sc.tr_wq);

	rc = trunner_check_magic(&sc);
	if (rc) {
		printk(KERN_ERR "trunner magic mismatch\n");
		goto error;
	}

	printk(KERN_INFO "trunner magic matches!\n");


	rc = platform_device_add_data(pdev, &sc, sizeof(sc));
	if (rc) {
		printk(KERN_ERR "trunner could not add data\n");
		goto error;
	}


	scp = pdev->dev.platform_data;


	rc = request_irq(irq, trunner_irq_handler, 0 /* flags */, DRIVER_NAME,
			 &pdev->dev);
	if (rc) {
		printk(KERN_ERR "trunner could not request IRQ %d\n", irq);
		goto error;
	}

	cdev_init(&scp->tr_cdev, &trunner_fops);
	kobject_set_name(&scp->tr_cdev.kobj, "%s%d", DRIVER_NAME, id);

	rc = cdev_add(&scp->tr_cdev, trunner_dev, 1);
	if (rc) {
		printk(KERN_ERR "trunner failed cdev_add\n");
		kobject_put(&scp->tr_cdev.kobj);
		goto error;
	}


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

	cdev_del(&sc->tr_cdev);
	free_irq(sc->tr_irq, &pdev->dev);
	iounmap(sc->tr_base);

	return 0;
}


#ifdef CONFIG_OF
static struct of_device_id trunner_match[] = {
	{ .compatible = "trunner", },
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

	rc = alloc_chrdev_region(&trunner_dev, 0, MAX_CDEVS, DRIVER_NAME);
	if (rc)
		return rc;

	rc = platform_driver_register(&trunner_platform_driver);

	return rc;
}


static void __exit
trunner_exit(void)
{
	printk(KERN_INFO "Test Runner Module unloaded\n");

	platform_driver_unregister(&trunner_platform_driver);

	unregister_chrdev_region(trunner_dev, MAX_CDEVS);
}


module_init(trunner_init);
module_exit(trunner_exit);


MODULE_LICENSE("GPL");
MODULE_AUTHOR("Alex Hornung <alex@alexhornung.com>");
MODULE_DESCRIPTION("Driver for the test runner module");
MODULE_SUPPORTED_DEVICE(DRIVER_NAME);
