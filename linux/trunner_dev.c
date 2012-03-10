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


static int
trunner_probe(void)
{
}


static int __init
trunner_init(void)
{
	printk(KERN_INFO "Test Runner Module loaded\n");

	return trunner_probe();
}


static void __exit
trunner_exit(void)
{
	printk(KERN_INFO "Test Runner Module unloaded\n");
}


module_init(trunner_init);
module_exit(trunner_exit);


MODULE_LICENSE("GPL");
MODULE_AUTHOR("Alex Hornung <alex@alexhornung.com>");
MODULE_DESCRIPTION("Driver for the test runner module");
MODULE_SUPPORTED_DEVICE("trunner");
