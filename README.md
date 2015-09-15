eXist Puppet Manifests
======================
[Puppet](https://puppetlabs.com) is a Configuration Management Utility, and we can use it to ensure a consistent and repeatable installation and configuration of [eXist](http://www.exist-db.org).

Here we provide Puppet manifests for eXist, with optional [nginx](http://nginx.org/en/) proxy support, and optional platform manifests for [Amazon EC2](http://aws.amazon.com/ec2/) and [GreenQloud](http://www.greenqloud.com) cloud instances.

1. `exist.pp` will install a fairly minimal eXist system for you where eXist is configured to run using the [Java Service Wrapper](http://http://wrapper.tanukisoftware.com/) under an `exist` user account. See the variables in the top of the file to change the data directory for eXist (assumes `/exist-data`) and various other config settings.

2. `exist-nginx.pp` will install nginx and set it up to proxy eXist.

3. `ec2-tiny.pp` will take an EC2 VM and set it up for running eXist. It expects the VM to have two volumes: `/dev/xvda`, for the OS and `/dev/xvdb` dedicated for the eXist database files. ***WARNING*** This script is descructive as it will reformat `/dev/xvdb` with a clean ext4 filesystem!


Installing eXist on EC2
=======================
1. Create a VM with two volumes: `/dev/xvda` for the OS, and `/dev/xvdb` for eXist's database files. Amazon Linux is recommended, although Ubuntu, RHEL or any derivatives of those should also work.

2. Connect to your new VM via SSH e.g. `ssh -i your-key.pem ec2-user@52.1.129.39`.

3. Run the following commands (on Amazon Linux) to clone this repo and execute the Puppet manifests:
```bash
sudo yum install git puppet3 augeas
sudo mkdir /etc/puppet/modules
sudo puppet module install puppetlabs/vcsrepo
sudo puppet module install puppetlabs/stdlib
sudo puppet module install herculesteam/augeasproviders
sudo puppet module install attachmentgenie-ufw

git clone https://github.com/adamretter/exist-puppet.git
cd exist-puppet
sudo puppet apply ec2-tiny.pp
sudo puppet apply exist.pp
sudo puppet apply exist-nginx.pp
``` 

4. If you are concerned with security, you should make sure that the firewall for your VM only allows SSH (TCP port 22), and HTTP access to nginxi (TCP port 80), with no direct external access to eXist (TCP port 8080). 

TODO
----
* Create an eXist module
* Sort out the templating
* Extract facts into external config file
