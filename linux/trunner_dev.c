#include <asm/irq.h>
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


#define DRIVER_NAME	"trunner"
#define MAX_CDEVS	8


#define TRUNNER_MAGIC_REG		0x7f
#define TRUNNER_DONE_REG		0x80
#define TRUNNER_ENABLE_REG		0x81

#define TRUNNER_MAGIC			0x0a


struct trunner_softc {
	struct cdev	tr_cdev;
	int		tr_busy;
	int		tr_id;
	int		tr_irq;
	uint8_t		*tr_base;
};


static dev_t trunner_dev;


static int
trunner_get_done(struct trunner_softc *sc)
{
	uint8_t d;

	d = readb(sc->tr_base + TRUNNER_DONE_REG);

	return (int)d;
}


static int
trunner_enable(struct trunner_softc *sc)
{
	uint8_t e = 1;
	int rc;


	if (sc->tr_busy)
		return EBUSY;

	rc = trunner_get_done(sc);
	if (!rc)
		return EBUSY;

	sc->tr_busy = 1;
	writeb(sc->tr_base + TRUNNER_ENABLE_REG, e);

	return 0;
}


static int
trunner_check_magic(struct trunner_softc *sc)
{
	uint8_t d;

	d = readb(sc->tr_base + TRUNNER_MAGIC_REG);

	return (d != TRUNNER_MAGIC) ? ENODEV : 0;
}








static struct file_operations trunner_fops = {
	.owner		= THIS_MODULE,
	.open		= trunner_open,
	.ioctl		= trunner_ioctl,
	.release	= trunner_release,

};






static int __devinit
trunner_probe(struct platform_device *pdev)
{
	struct trunner_softc sc;
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


	rc = request_irq(irq, trunner_irq_handler, 0 /* flags */, DRIVER_NAME,
			 &pdev->dev);
	if (rc) {
		printk(KERN_ERR "trunner could not request IRQ %d\n", irq);
		goto error;
	}

	sc.tr_busy = 0;
	sc.tr_id = id;
	sc.tr_irq = irq;
	sc.tr_base = tr_base;

	rc = trunner_check_magic(&sc);
	if (rc) {
		printk(KERN_ERR "trunner magic mismatch\n");
		goto error;
	}

	printk(KERN_INFO "trunner magic matches!\n");


	rc = platform_device_add_data(pdev, &tr_softc, sizeof(tr_softc));
	if (rc) {
		printk(KERN_ERR "trunner could not add data\n");
		goto error;
	}

	cdev_init(&sc.tr_cdev, &trunner_fops);
	kobject_set_name(&sc.tr_cdev->kobj, "%s%d", DRIVER_NAME, id);

	rc = cdev_add(&sc.tr_cdev, trunner_dev, 1);
	if (rc) {
		printk(KERN_ERR "trunner failed cdev_add\n");
		kobject_put(&sc.tr_cdev.kobj);
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
	free_irq(irq, &pdev->dev);
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
		.of_match_table	= of_match_ptr(trunner_match),
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
