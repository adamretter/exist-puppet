include lvm
#include motd
include ufw

##
# Puppet script for configuring
# a base GreenQloud Ubuntu Server  based system
# in preparation for installing eXist
#
# @author Adam Retter <adam.retter@googlemail.com>
#
##

$locale = "en_GB.UTF-8 UTF-8"
$tz = "Europe/London"
$data_fs_dev = "/dev/vdb"
$data_root = "/data"
$exist_data = "/data/exist"

###
# Set the firewall basics
###
ufw::allow { "allow-ssh-from-all":
	port => 22,
}

###
# Set the locale
###
class { "locales":
	default_locale => $locale,
	locales => [$locale],
}

class { "timezone":
	timezone => $tz,
}

##
# Create a storage filesytem for eXist's database
##
package { "xfsprogs":
	ensure => present,
}

package { "xfsdump":
	ensure => present,
}

lvm::volume { "data":
	ensure => present,
	vg => "data",
	pv => $data_fs_dev,
	fstype => "xfs",
	require => [
		Package["xfsprogs"],
		Package["xfsdump"]
	],
}

##
# Mount point for the exist filesystem
##
file { $data_root:
	ensure => directory,
	mode => 700,
} ~>

file { $exist_data:
        ensure => directory,
        mode => 700,
}

mount { $data_root:
	device => "/dev/data/data",
	fstype => "xfs",
	ensure => mounted,
	options => defaults,
	dump => 0,
	pass => 2,
	require => File[$data_root]
}

##
# Add eXist banner to the MOTD
##
class { "motd":
	template => "./templates/motd.erb",
}


file { "exist motd banner":
	path => "/etc/update-motd.d/10-exist-banner",
	ensure => present,
	mode => 0755,
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

#exec { "update motd":
#	command => "/usr/sbin/update-motd",
#	require => File["exist motd banner"]
#}
