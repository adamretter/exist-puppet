##
# Puppet script for configuring
# a base Amazon EC2 EL based system
# in preparation for installing eXist
#
# @author Adam Retter <adam.retter@googlemail.com>
#
##

$swap_size = 524288
$exist_data_fs_dev = "/dev/xvdb"
$exist_data = "/exist-data"


##
# Create Swap file and Switch on the Swap
##
exec { "create swapfile":
	command => "/bin/dd if=/dev/zero of=/swapfile1 bs=1024 count=${swap_size}",
	creates => "/swapfile1"
}

exec { "mkswap":
	command => "/sbin/mkswap /swapfile1",
	refreshonly => true,
	subscribe => Exec["create swapfile"]
}

exec { "swapon":
	command => "/sbin/swapon /swapfile1",
	refreshonly => true,
	subscribe => Exec["mkswap"],
	before => Mount["swap"]
}

mount { "swap":
	device => "/swapfile1",
	fstype => "swap",
	ensure => mounted,
	options => defaults,
	dump => 0,
	pass => 0,
	require => Exec["create swapfile"]
}

##
# Create a storage filesytem for eXist's database
##
exec { "make database fs":
	command => "/sbin/mkfs -t ext4 ${exist_data_fs_dev}",
	unless => "/bin/mount | /bin/grep ${exist_data_fs_dev} | /bin/grep ext4",
	before => Mount[$exist_data_fs_dev]
}

mount { $exist_data_fs_dev:
	device => $exist_data,
	fstype => "ext4",
	ensure => mounted,
	options => defaults,
	dump => 0,
	pass => 2
}

file { $exist_data:
	ensure => directory,
	owner => "exist",
	group => "exist",
	mode => 750,
	require => Mount[$exist_data_fs_dev]
}


##
# Add eXist banner to the MOTD
##
file { "/etc/update-motd.d/10-exist-banner":
	ensure => present,
	content =>
'#!/bin/sh

cat << "EOF"
        ____  ___.__           __ 
  ____  \   \/  /|__|  _______/  |_
_/ __ \  \     / |  | /  ___/\   __\
\  ___/  /     \ |  | \___ \  |  |
 \___  >/___/\  \|__|/____  > |__|
     \/       \_/         \/

NoSQL Native XML Database
and Application Platform

http://www.exist-db.org

EOF'
}

