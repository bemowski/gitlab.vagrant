
What is this?
=============

The GitLab install is fairly complex.  But it looks to be worth it.  

This is a Vagrant configuration to install Ubuntu 14.04 (trusty) 64 bit, and then install 
GitLab and all of its dependencies.

The vagrant bootstrap.sh used to install and configure everything is a very slight adaptation of the instructions outlined here:
https://github.com/gitlabhq/gitlabhq/blob/master/doc/install/installation.md



Prerequisites 
-------------

* Vagrant - 1.6.x
* Virtualbox - 4.3.10

* You need vt-x extensions enabled in the bios to run a 64 bit VMs.  At least I did.  If you have not run other VirtualBox 64 bit VMs - you may run into this.  If not - just give it a go.  I think Mac users can ignore this.

How to use
----------

1. Clone the this repo.
2. Edit the config.sh - where you see a few environment variables.
3. vagrant up
4. Wait a long time.
5. profit.

Post Installation 
=================

After the installation you should be able to hit your GitLab server on the private (host-only) ip created for the VM on port 80.  

You can login as admin using:
   admin@local.host / 5iveL!fe

You will be required to change that password on login to something longer than 8 characters.

Adding Users
------------
As administrator you can add users.  You cannot set their passwords - they have to be emailed to the users.  Your postfix install (Step 1) should support outbound smtp.

Uploading an existing git project
---------------------------------

Create the project as a user or as admin 


Log Files
---------
Most GitLab related logs re in /home/git/gitlab/log 

Nginx's logs are in /var/log/nginx



Feedback
========

Send feedback / comments to bemowski@yahoo.com.  

Useful Pull Requests are welcome.





