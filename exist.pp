##
# Puppet script for installing
# eXist on Linux/Unix systems
#
# @author Adam Retter <adam.retter@googlemail.com>
#
##

$exist_revision = "eXist-2.1"
$exist_home = "/usr/local/exist"
$exist_data = "/exist-data"
$exist_cache_size = "128M"
$exist_collection_cache_size = "24M"



exec { "puppetlabs/stdlib":
	command => "/usr/sbin/puppet module install puppetlabs/stdlib",
	creates => "/etc/puppet/modules/stdlib"
}

exec { "puppetlabs/vcsrepo":
	command => "/usr/sbin/puppet module install puppetlabs/vcsrepo",
	creates => "/etc/puppet/modules/vcsrepo"
}

##
# Make sure that NTP is installed and running
##
package { 'ntp': ensure => installed }

service { "ntpd":
    ensure => running,
    enable => true,
    pattern => 'ntpd',
    subscribe => Package["ntp"]
}

##
# Create 'exist' user and group
# and prevent SSH access by that user
##
group { "exist":
        ensure => present,
	system => true
}

user { "exist":
	ensure => present,
	system => true,
	gid => "exist",
	membership => minimum,
	managehome => true,
	shell => "/bin/bash",
	comment => "eXist Server",
	require => Group["exist"]
}

file { "/etc/ssh/sshd_config":
	ensure => present
}->
file_line { "deny exist ssh":
	line => "DenyUsers exist",
	path => "/etc/ssh/sshd_config",
	require => Exec["puppetlabs/stdlib"]
}

##
# Ensure eXist pre-requisite packages are installed
##
package { 'java-1.7.0-openjdk':
	ensure => installed
}

package { 'java-1.7.0-openjdk-devel':
	ensure => installed,
}

package { 'git':
	ensure => installed,
}

##
# Clone eXist from GitHub
##
vcsrepo { $exist_home:
	ensure => present,
	provider => git,
	source => "https://github.com/eXist-db/exist.git",
	revision => $exist_revision,
	require => [Exec["puppetlabs/vcsrepo"], Package["git"]],
	before => File[$exist_home]
}

file { $exist_home:
	ensure => present,
	owner => "exist",
	group => "exist",
	mode => 700,
	recurse => true
}

##
# Build eXist from src
##
file { "${exist_home}/extensions/local.build.properties":
	ensure => present,
	content =>
"include.feature.contentextraction = true
include.feature.security.ldap = false
include.feature.tomcat-realm = false
include.feature.xslt = false
include.module.cache = false
include.module.scheduler = true
include.module.xslfo = true
include.module.process = false",
	require => File[$exist_home]
}

exec { "build eXist":
	cwd => $exist_home,
	command => "${exist_home}/build.sh",
	timeout => 0,
	user => "exist",
	group => "exist",
	refreshonly => true,
	subscribe => Vcsrepo[$exist_home],
	require => File["${exist_home}/extensions/local.build.properties"]
}

#file { "${exist_home}/conf.xml":
#	ensure => present,
#	content => template("conf.xml.erb"),
#	require => File[$exist_home]
#}

file { "/home/exist/.bash_profile":
	ensure => present,
	require => User["exist"]
}->
file_line { "EXIST_HOME in bash_profile":
	line => "export EXIST_HOME=${exist_home}",
	path => "/home/exist/.bash_profile",
	require => [
		Exec["puppetlabs/stdlib"],
		User["exist"],
		File[$exist_home]
	]
}
