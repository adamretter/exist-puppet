exist-puppet
============

Puppet manifests for eXist-db (with optional nginx proxy)
In additionl we provide ioptional platform manifests for Amazon EC2 and GreenQloud

1. `exist.pp` will install a fairly minimal eXist system for you where eXist is configured to run using the Java Service Wrapper under an `exist` user account. See the variables in the top of the file to change the data directory for eXist (assumes `/exist-data`) and various other config settings.

2. `exist-nginx.pp` will install nginx and set it up to proxy eXist.

3. `ec2-tiny.pp` will take an EC2 VM and set it up for running eXist. It expects the VM to have two volumes: `/dev/xvda`, for the OS and `/dev/xvdb` dedicated for the eXist database files.


Installing eXist on EC2
=======================
1. Create a VM with two volumes: `/dev/xvda` for the OS and `/dev/xvdb` for eXist's database files. Amazon Linux is recommended, although Ubuntu, RHEL or any derivatives of those should also work.

2. Connect to your new VM via SSH e.g. `ssh -i your-key.pem ec2-user@52.1.129.39`.

3. Run the following commands to clone this repo and execite the Puppet manifests:
```bash
sudo yum install git puppet3 augeas
sudo mkdir /etc/puppet/modules
sudo puppet module install puppetlabs/vcsrepo
sudo puppet module install puppetlabs/stdlib
sudo puppet module install herculesteam/augeasproviders

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
