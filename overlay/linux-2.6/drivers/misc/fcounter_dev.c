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


#define DRIVER_NAME	"fcounter"
#define MAX_CDEVS	8


#define MAJOR_NUM		0xFC
#define FCOUNTER_IOC_ENABLE	_IO(MAJOR_NUM, 0)
#define FCOUNTER_IOC_GET_COUNT	_IOR(MAJOR_NUM, 1, uint32_t)
#define FCOUNTER_IOC_GET_MAGIC	_IOR(MAJOR_NUM, 2, uint32_t)
#define FCOUNTER_IOC_SET_CYCLES	_IOW(MAJOR_NUM, 3, uint32_t)
#define FCOUNTER_IOC_SET_IPSEL	_IOW(MAJOR_NUM, 4, uint32_t)


#define FCOUNTER_IRQ_REG	0x04
#define FCOUNTER_MAGIC_REG	0x05
#define FCOUNTER_INPUT_SEL_REG	0x00
#define FCOUNTER_CYCLECOUNT_REG	0x03
#define FCOUNTER_EDGECOUNT_REG	0x02

#define FCOUNTER_ENABLE_REG	0x0A

#define FCOUNTER_MAGIC		0x0A


struct fcounter_softc {
	struct cdev	fc_cdev;
	wait_queue_head_t	fc_wq;
	int		fc_busy;
	int		fc_id;
	int		fc_irq;
	uint8_t		*fc_base;
};


static dev_t fcounter_dev;
static int fcounter_major;
static struct class *fcounter_class;


static uint32_t
fcounter_read_reg(struct fcounter_softc *sc, int reg)
{
	return ioread32(sc->fc_base + reg);
}


static void
fcounter_write_reg(struct fcounter_softc *sc, int reg, uint32_t v)
{
	iowrite32(v, sc->fc_base + reg);
}


static int
fcounter_enable(struct fcounter_softc *sc)
{
	uint32_t e = 1;
	int rc;

	if (sc->fc_busy)
		return -EBUSY;

	sc->fc_busy = 1;
	fcounter_write_reg(sc, FCOUNTER_ENABLE_REG, e);

	return 0;
}


static int
fcounter_check_magic(struct fcounter_softc *sc)
{
	uint32_t d;

	d = fcounter_read_reg(sc, FCOUNTER_MAGIC_REG);

	return (d != FCOUNTER_MAGIC) ? ENODEV : 0;
}


static int
fcounter_open(struct inode *inode, struct file *file)
{
	try_module_get(THIS_MODULE);

	return 0;
}


static int
fcounter_release(struct inode *inode, struct file *file)
{
	module_put(THIS_MODULE);

	return 0;
}


ssize_t
fcounter_read(struct file *file, char __user *buf, size_t count,
	      loff_t *fpos)
{
	struct fcounter_softc *sc;
	uint32_t d;
	ssize_t rval = 0;

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct fcounter_softc, fc_cdev);

	if (count != sizeof(d))
		return -EINVAL;

	d = fcounter_read_reg(sc, FCOUNTER_EDGECOUNT_REG);
	if (copy_to_user(buf, &d, sizeof(d)))
		return -EFAULT;

	*fpos = 0;

	return sizeof(d);
}


static long
fcounter_ioctl(struct file *file,
	      unsigned int cmd, unsigned long param)
{
	struct fcounter_softc *sc;
	uint32_t d;
	int rc = 0;

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct fcounter_softc, fc_cdev);

	switch (cmd) {
	case FCOUNTER_IOC_ENABLE:
		rc = fcounter_enable(sc);
		break;


	case FCOUNTER_IOC_GET_COUNT:
		if (!access_ok(VERIFY_WRITE, (void *)param, sizeof(uint32_t)))
			return -ENOTTY;

		d = fcounter_read_reg(sc, FCOUNTER_EDGECOUNT_REG);
		put_user(d, (uint32_t *)param);
		break;


	case FCOUNTER_IOC_GET_MAGIC:
		if (!access_ok(VERIFY_WRITE, (void *)param, sizeof(uint32_t)))
			return -ENOTTY;

		d = fcounter_read_reg(sc, FCOUNTER_MAGIC_REG);
		put_user(d, (uint32_t *)param);
		break;


	case FCOUNTER_IOC_SET_CYCLES:
		if (!access_ok(VERIFY_READ, (void *)param, sizeof(uint32_t)))
			return -ENOTTY;

		if (sc->fc_busy)
			return -EBUSY;

		get_user(d, (uint32_t *)param);

		fcounter_write_reg(sc, FCOUNTER_CYCLECOUNT_REG, d);
		break;


	case FCOUNTER_IOC_SET_IPSEL:
		if (!access_ok(VERIFY_READ, (void *)param, sizeof(uint32_t)))
			return -ENOTTY;

		if (sc->fc_busy)
			return -EBUSY;

		get_user(d, (uint32_t *)param);

		fcounter_write_reg(sc, FCOUNTER_INPUT_SEL_REG, d);
		break;


	default:
		return -ENOTTY;
	}

	return rc;
}


static unsigned int
fcounter_poll(struct file *file, struct poll_table_struct *pts)
{
	struct fcounter_softc *sc;
	unsigned int mask = 0;

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct fcounter_softc, fc_cdev);

	poll_wait(file, &sc->fc_wq, pts);

	if (!sc->fc_busy)
		mask |= POLLIN | POLLRDNORM;

	return mask;
}


static struct file_operations fcounter_fops = {
	.owner		= THIS_MODULE,
	.open		= fcounter_open,
	.read		= fcounter_read,
	.poll		= fcounter_poll,
	.unlocked_ioctl	= fcounter_ioctl,
	.release	= fcounter_release,
};


static irqreturn_t
fcounter_irq_handler(int irq, void *priv)
{
	struct device *dev = priv;
	struct fcounter_softc *sc = dev->platform_data;
	uint8_t irqs;

	/* XXX: temporary debug */
	dev_info(dev, "fcounter_irq\n");

	/* Reading the IRQ register clears the interrupt(s) */
	irqs = fcounter_read_reg(sc, FCOUNTER_IRQ_REG);

	sc->fc_busy = 0;

	wake_up(&sc->fc_wq);

	return IRQ_HANDLED;
}


static int __devinit
fcounter_probe(struct platform_device *pdev)
{
	struct fcounter_softc sc, *scp;
	struct resource *res_mem;
	void *fc_base;
	int id, irq;
	int rc;

	irq = -1;
	fc_base = NULL;

	id = (pdev->id >= 0) ? pdev->id : 0;

	irq = platform_get_irq(pdev, 0);
	if (irq == ENXIO)
		return -ENODEV;

	res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (res_mem == NULL) {
		dev_err(&pdev->dev, "platform_get_resource failed!\n");
		return -ENODEV;
	}

	fc_base = ioremap(res_mem->start, resource_size(res_mem));
	if (fc_base == NULL) {
		dev_err(&pdev->dev, "ioremap failed!\n");
		return -ENODEV;
	}

	sc.fc_busy = 0;
	sc.fc_id = id;
	sc.fc_irq = irq;
	sc.fc_base = fc_base;

	rc = fcounter_check_magic(&sc);
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
	init_waitqueue_head(&scp->fc_wq);

	rc = request_irq(irq, fcounter_irq_handler, 0 /* flags */, DRIVER_NAME,
			 &pdev->dev);
	if (rc) {
		dev_err(&pdev->dev, "request_irq failed!\n");
		goto error;
	}

	cdev_init(&scp->fc_cdev, &fcounter_fops);
	kobject_set_name(&scp->fc_cdev.kobj, "%s%d", DRIVER_NAME, id);

	rc = cdev_add(&scp->fc_cdev, MKDEV(fcounter_major, id), 1);
	if (rc) {
		dev_err(&pdev->dev, "cdev_add failed!\n");
		kobject_put(&scp->fc_cdev.kobj);
		goto error;
	}

	if (IS_ERR(device_create(fcounter_class, &pdev->dev,
				MKDEV(fcounter_major, id), NULL,
				"%s%d", DRIVER_NAME, id))) {
		dev_err(&pdev->dev, "device_create failed!\n");
		cdev_del(&scp->fc_cdev);
		goto error;
	}

	dev_info(&pdev->dev, "Frequency Counter device %d, irq %d\n", id, irq);

	return 0;


error:
	if (irq >= 0)
		free_irq(irq, &pdev->dev);
	if (fc_base)
		iounmap(fc_base);

	return -ENODEV;
}


static int __devexit
fcounter_remove(struct platform_device *pdev)
{
	struct fcounter_softc *sc = pdev->dev.platform_data;

	device_destroy(fcounter_class, MKDEV(fcounter_major, sc->fc_id));
	cdev_del(&sc->fc_cdev);
	free_irq(sc->fc_irq, &pdev->dev);
	iounmap(sc->fc_base);

	return 0;
}


#ifdef CONFIG_OF
static struct of_device_id fcounter_match[] = {
	{ .compatible = "fcounter,fcounter-1.0", },
	{}
};
MODULE_DEVICE_TABLE(of, fcounter_match);
#endif /* CONFIG_OF */

static struct platform_driver fcounter_platform_driver = {
	.probe = fcounter_probe,
	.remove = __devexit_p(fcounter_remove),
	.driver = {
		.name		= DRIVER_NAME,
		.owner		= THIS_MODULE,
#ifdef CONFIG_OF
		.of_match_table	= of_match_ptr(fcounter_match),
#endif
	},
};


static int __init
fcounter_init(void)
{
	int rc;

	printk(KERN_INFO "Frequency Counter Module loaded\n");

	fcounter_class = class_create(THIS_MODULE, "fcounter");
	if (IS_ERR(fcounter_class)) {
		rc = PTR_ERR(fcounter_class);
		printk(KERN_ERR "fcounter: class_create failed!\n");
		return rc;
	}

	rc = alloc_chrdev_region(&fcounter_dev, 0, MAX_CDEVS, DRIVER_NAME);
	if (rc) {
		printk(KERN_ERR "fcounter: alloc_chrdev_region failed!\n");
		class_destroy(fcounter_class);
		return rc;
	}

	fcounter_major = MAJOR(fcounter_dev);

	rc = platform_driver_register(&fcounter_platform_driver);

	return rc;
}


static void __exit
fcounter_exit(void)
{
	printk(KERN_INFO "Frequency Counter Module unloaded\n");

	platform_driver_unregister(&fcounter_platform_driver);

	unregister_chrdev_region(fcounter_dev, MAX_CDEVS);

	class_destroy(fcounter_class);
}


module_init(fcounter_init);
module_exit(fcounter_exit);


MODULE_LICENSE("GPL");
MODULE_AUTHOR("Alex Hornung <alex@alexhornung.com>");
MODULE_DESCRIPTION("Driver for the frequency counter module");
MODULE_SUPPORTED_DEVICE(DRIVER_NAME);
