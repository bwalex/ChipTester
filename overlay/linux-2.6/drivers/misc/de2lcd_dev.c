#include <asm/irq.h>
#include <asm/io.h>
#include <asm/uaccess.h>
#include <linux/types.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/kernel.h>
#include <linux/signal.h>
#include <linux/sched.h>
#include <linux/timer.h>
#include <linux/delay.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/errno.h>


#define DRIVER_NAME	"de2lcd"
#define MAX_CDEVS	8

#define MAJOR_NUM		0xFD
#define DE2LCD_IOC_CLEAR	_IO(MAJOR_NUM, 0)
#define DE2LCD_IOC_CURSOR_ON	_IO(MAJOR_NUM, 1)
#define DE2LCD_IOC_CURSOR_OFF	_IO(MAJOR_NUM, 2)
#define DE2LCD_IOC_SET_SHL	_IOW(MAJOR_NUM, 3, int)
#define DE2LCD_IOC_TEST		_IO(MAJOR_NUM, 4)


#define INST_REG	0x00
#define DATA_REG	0x08

#define CURSOR_TOPLEFT	0x00
#define CURSOR_BOTLEFT	0x40

#define INST_CLEAR	0x01
#define INST_HOME	0x02
#define INST_CURSOR_ON	0x0f
#define INST_CURSOR_OFF	0x0c
#define INST_SET_CURSOR	0x80
#define INST_SHL	0x18
#define INST_SHR	0x1C

#define N_CHARS		16
#define N_CHARS_EXT	40
#define N_LINES		2

struct de2lcd_softc {
	struct cdev	de_cdev;
	int		de_busy;
	int		de_id;
	int		de_shl_ms;
	uint8_t		*de_base;
};


static dev_t de2lcd_dev;
static int de2lcd_major;
static struct class *de2lcd_class;
static struct timer_list de2lcd_timer;


static void
de2lcd_write_instreg(struct de2lcd_softc *sc, uint8_t v)
{
	writeb(v, sc->de_base + INST_REG);
	mdelay(2);
}


static void
de2lcd_write_datareg(struct de2lcd_softc *sc, uint8_t v)
{
	writeb(v, sc->de_base + DATA_REG);
	udelay(100);
}


static int
de2lcd_shl(struct de2lcd_softc *sc)
{
	de2lcd_write_instreg(sc, INST_SHL);

	return 0;
}


static int
de2lcd_clear(struct de2lcd_softc *sc)
{
	de2lcd_write_instreg(sc, INST_CLEAR);

	return 0;
}


static int
de2lcd_cursor_on(struct de2lcd_softc *sc)
{
	de2lcd_write_instreg(sc, INST_CURSOR_ON);

	return 0;
}


static int
de2lcd_cursor_off(struct de2lcd_softc *sc)
{
	de2lcd_write_instreg(sc, INST_CURSOR_OFF);

	return 0;
}


static int
de2lcd_write_at(struct de2lcd_softc *sc, int loc, char *buf, size_t count)
{
	uint8_t b;

	de2lcd_write_instreg(sc, INST_HOME);

	b = (uint8_t)loc | INST_SET_CURSOR;
	de2lcd_write_instreg(sc, b);

	while (count--) {
		b = *buf++;
		de2lcd_write_datareg(sc, b);
	}

	return 0;
}


static int
de2lcd_test(struct de2lcd_softc *sc)
{
	de2lcd_write_at(sc, 0, "Hello World!", strlen("Hello World!"));

	return 0;
}


static int
de2lcd_open(struct inode *inode, struct file *file)
{
	try_module_get(THIS_MODULE);

	return 0;
}


static int
de2lcd_release(struct inode *inode, struct file *file)
{
	module_put(THIS_MODULE);

	return 0;
}


static void
de2lcd_shl_task(unsigned long data)
{
	struct de2lcd_softc *sc = (struct de2lcd_softc *)data;
	int e;

	de2lcd_shl(sc);

	e = mod_timer(&de2lcd_timer,
		      jiffies + msecs_to_jiffies(sc->de_shl_ms));
	if (e)
		printk("Error in mod_timer (de2lcd_shl_task)");
}


static int
de2lcd_schedule_shl(struct de2lcd_softc *sc, int ms)
{
	int e;

	if (sc->de_shl_ms != 0) {
		del_timer(&de2lcd_timer);
		de2lcd_write_instreg(sc, INST_HOME);
	}

	sc->de_shl_ms = ms;

	if (ms == 0)
		return 0;

	setup_timer(&de2lcd_timer, de2lcd_shl_task, (unsigned long)sc);
	e = mod_timer(&de2lcd_timer, jiffies + msecs_to_jiffies(ms));
	if (e) {
		printk("Error in mod_timer");
		return -EINVAL;
	}

	return 0;
}


static long
de2lcd_ioctl(struct file *file,
	     unsigned int cmd, unsigned long param)
{
	struct de2lcd_softc *sc;
	uint16_t ms;
	int rc = 0;

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct de2lcd_softc, de_cdev);

	switch (cmd) {
	case DE2LCD_IOC_CLEAR:
		rc = de2lcd_clear(sc);
		break;


	case DE2LCD_IOC_CURSOR_ON:
		rc = de2lcd_cursor_on(sc);
		break;


	case DE2LCD_IOC_CURSOR_OFF:
		rc = de2lcd_cursor_off(sc);
		break;


	case DE2LCD_IOC_TEST:
		rc = de2lcd_test(sc);
		break;


	case DE2LCD_IOC_SET_SHL:
		if (!access_ok(VERIFY_READ, (void *)param, sizeof(int)))
			return -ENOTTY;

		get_user(ms, (int *)param);

		rc = de2lcd_schedule_shl(sc, ms);
		break;


	default:
		return -ENOTTY;
	}

	return rc;
}



static ssize_t
de2lcd_write(struct file *file, const char __user *buf, size_t count,
	     loff_t *fpos)
{
	struct de2lcd_softc *sc;
	char linebuf[2*N_CHARS_EXT + 1];

	sc = container_of(file->f_dentry->d_inode->i_cdev,
			  struct de2lcd_softc, de_cdev);

	if ((*fpos <  CURSOR_BOTLEFT && *fpos >= N_CHARS_EXT) ||
	    (*fpos >= CURSOR_BOTLEFT + N_CHARS_EXT))
		return -EINVAL;

	if (count >= sizeof(linebuf))
		return -ENOMEM;

	if (copy_from_user(linebuf, buf, count))
		return -EFAULT;

	de2lcd_write_at(sc, (int)*fpos, linebuf, count);

	*fpos += count;
	if (*fpos >= N_CHARS_EXT && *fpos < CURSOR_BOTLEFT)
		*fpos += (CURSOR_BOTLEFT - N_CHARS_EXT);

	if (*fpos >= CURSOR_BOTLEFT + N_CHARS_EXT)
		*fpos = (*fpos - 2*N_CHARS_EXT);

	return (ssize_t)count;
}


static struct file_operations de2lcd_fops = {
	.owner		= THIS_MODULE,
	.open		= de2lcd_open,
	.write          = de2lcd_write,
	.unlocked_ioctl	= de2lcd_ioctl,
	.release	= de2lcd_release,
};


static int __devinit
de2lcd_probe(struct platform_device *pdev)
{
	struct de2lcd_softc sc, *scp;
	struct resource *res_mem;
	void *de_base;
	int id;
	int rc;

	de_base = NULL;

	id = (pdev->id >= 0) ? pdev->id : 0;

	res_mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (res_mem == NULL) {
		dev_err(&pdev->dev, "platform_get_resource failed!\n");
		return -ENODEV;
	}

	de_base = ioremap(res_mem->start, resource_size(res_mem));
	if (de_base == NULL) {
		dev_err(&pdev->dev, "ioremap failed!\n");
		return -ENODEV;
	}

	sc.de_busy = 0;
	sc.de_id = id;
	sc.de_base = de_base;
	sc.de_shl_ms = 0;

	rc = platform_device_add_data(pdev, &sc, sizeof(sc));
	if (rc) {
		dev_err(&pdev->dev, "platform_device_add_data failed!\n");
		goto error;
	}

	scp = pdev->dev.platform_data;

	cdev_init(&scp->de_cdev, &de2lcd_fops);
	kobject_set_name(&scp->de_cdev.kobj, "%s%d", DRIVER_NAME, id);

	rc = cdev_add(&scp->de_cdev, MKDEV(de2lcd_major, id), 1);
	if (rc) {
		dev_err(&pdev->dev, "cdev_add failed!\n");
		kobject_put(&scp->de_cdev.kobj);
		goto error;
	}

	if (IS_ERR(device_create(de2lcd_class, &pdev->dev,
				MKDEV(de2lcd_major, id), NULL,
				"%s%d", DRIVER_NAME, id))) {
		dev_err(&pdev->dev, "device_create failed!\n");
		cdev_del(&scp->de_cdev);
		goto error;
	}

	dev_info(&pdev->dev, "DE2 LCD %d\n", id);

	return 0;


error:
	if (de_base)
		iounmap(de_base);

	return -ENODEV;
}


static int __devexit
de2lcd_remove(struct platform_device *pdev)
{
	struct de2lcd_softc *sc = pdev->dev.platform_data;

	device_destroy(de2lcd_class, MKDEV(de2lcd_major, sc->de_id));
	cdev_del(&sc->de_cdev);
	iounmap(sc->de_base);

	return 0;
}


#ifdef CONFIG_OF
static struct of_device_id de2lcd_match[] = {
	{ .compatible = "de2lcd,de2lcd-1.0", },
	{}
};
MODULE_DEVICE_TABLE(of, de2lcd_match);
#endif /* CONFIG_OF */

static struct platform_driver de2lcd_platform_driver = {
	.probe = de2lcd_probe,
	.remove = __devexit_p(de2lcd_remove),
	.driver = {
		.name		= DRIVER_NAME,
		.owner		= THIS_MODULE,
#ifdef CONFIG_OF
		.of_match_table	= of_match_ptr(de2lcd_match),
#endif
	},
};


static int __init
de2lcd_init(void)
{
	int rc;

	printk(KERN_INFO "DE2LCD Module loaded\n");

	de2lcd_class = class_create(THIS_MODULE, "de2lcd");
	if (IS_ERR(de2lcd_class)) {
		rc = PTR_ERR(de2lcd_class);
		printk(KERN_ERR "de2lcd: class_create failed!\n");
		return rc;
	}

	rc = alloc_chrdev_region(&de2lcd_dev, 0, MAX_CDEVS, DRIVER_NAME);
	if (rc) {
		printk(KERN_ERR "de2lcd: alloc_chrdev_region failed!\n");
		class_destroy(de2lcd_class);
		return rc;
	}

	de2lcd_major = MAJOR(de2lcd_dev);

	rc = platform_driver_register(&de2lcd_platform_driver);

	return rc;
}


static void __exit
de2lcd_exit(void)
{
	printk(KERN_INFO "DE2LCD Module unloaded\n");

	platform_driver_unregister(&de2lcd_platform_driver);

	unregister_chrdev_region(de2lcd_dev, MAX_CDEVS);

	class_destroy(de2lcd_class);
}


module_init(de2lcd_init);
module_exit(de2lcd_exit);


MODULE_LICENSE("GPL");
MODULE_AUTHOR("Alex Hornung <alex@alexhornung.com>");
MODULE_DESCRIPTION("Driver for the character LCD on the DE2 boards");
MODULE_SUPPORTED_DEVICE(DRIVER_NAME);
