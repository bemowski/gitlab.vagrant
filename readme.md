
What is this?
=============

The GitLab install is fairly complex.  But it looks to be worth it.  

This is a Vagrant configuration to install Ubuntu 14.04 (trusty) 64 bit, and then install 
GitLab and all of its dependencies.


Prerequisites 
-------------

* Vagrant - 1.6.x
* Virtualbox - 4.3.10

* You need vt-x extensions enabled in the bios to run a 64 bit VMs.  At least I did.  If you have not run other VirtualBox 64 bit VMs - you may run into this.  If not - just give it a go.  I think Mac users can ignore this.

How to use
----------

1. Clone the this repo.
2. Edit the top of bootstrap.sh - where you see a few environment variables.
3. vagrant up
4. Wait a long time.
5. profit.


