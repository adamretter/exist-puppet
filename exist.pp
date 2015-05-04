##
# Puppet script for installing
# eXist on Linux/Unix systems
#
# @author Adam Retter <adam.retter@googlemail.com>
#
##

$exist_revision = "eXist-2.2"
$exist_home = "/usr/local/exist"
$exist_data = "/exist-data"
$exist_cache_size = "128M"
$exist_collection_cache_size = "24M"

$rhel_pkg_jdk = "java-1.7.0-openjdk-devel"
$rhel_pkg_jre = "java-1.7.0-openjdk"
$deb_pkg_jdk = "openjdk-7-jdk"
$deb_pkg_jre = "openjdk-7-jre"


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

sshd_config { "DenyUsers":
	ensure => present,
	value  => [
		"exist"
	],
	require => User["exist"]
}

file { $exist_data:
	ensure => directory,
	owner => "exist",
	group => "exist",
	mode => 0760,
	require => [
		User["exist"],
		Group["exist"]
	]
}

##
# Ensure eXist pre-requisite packages are installed
##

$pkg_jre = $operatingsystem ? {
	centos => $rhel_pkg_jre,
	redhat => $rhel_pkg_jre,
	Amazon => $rhel_pkg_jre,
	default => $deb_pkg_jre
}

$pkg_jdk = $operatingsystem ? {
	centos => $rhel_pkg_jdk,
	redhat => $rhel_pkg_jdk,
	Amazon => $rhel_pkg_jdk,
	default => $deb_pkg_jdk
}

package { $pkg_jre:
	ensure => installed
}

package { $pkg_jdk:
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
	before => File[$exist_home]
}

file { $exist_home:
	ensure => present,
	owner => "exist",
	group => "exist",
	mode => "g=-rwx,o=-rwx",
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
include.module.xslfo.url = http://apache.cs.uu.nl/xmlgraphics/fop/binaries/fop-1.1-bin.zip
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

file { "/home/exist/.bash_profile":
	ensure => present,
	require => User["exist"]
}->
file_line { "EXIST_HOME in bash_profile":
	line => "export EXIST_HOME=${exist_home}",
	path => "/home/exist/.bash_profile",
	require => [
		User["exist"],
		File[$exist_home]
	]
}

augeas { "conf.xml":
	lens => "Xml.lns",
	incl => "$exist_home/conf.xml",
	context => "/files$exist_home/conf.xml/",
	changes => [
		"set exist/db-connection/#attribute/files $exist_data",
		"set exist/db-connection/#attribute/cacheSize $exist_cache_size",
		"set exist/db-connection/#attribute/collectionCache $exist_collection_cache_size",
		"set exist/db-connection/recovery/#attribute/journal-dir $exist_data",
		"set exist/serializer/#attribute/enable-xsl yes",

		"set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/contentextraction",
		"set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.contentextraction.xquery.ContentExtractionModule",

		"set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/counter",
                "set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.xquery.modules.counter.CounterModule",

		"set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/exi",
                "set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.xquery.modules.exi.ExiModule",

		"set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/image",
                "set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.xquery.modules.image.ImageModule",

                "set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/mail",
                "set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.xquery.modules.mail.MailModule",

                "set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/scheduler",
                "set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.xquery.modules.scheduler.SchedulerModule",

                "set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/sql",
                "set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.xquery.modules.sql.SQLModule",

                "set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/xmldiff",
                "set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.xquery.modules.xmldiff.XmlDiffModule",

                "set exist/xquery/builtin-modules/module[last()+1]/#attribute/uri http://exist-db.org/xquery/xslfo",
                "set exist/xquery/builtin-modules/module[last()]/#attribute/class org.exist.xquery.modules.xslfo.XSLFOModule",
		"set exist/xquery/builtin-modules/module[last()]/parameter/#attribute/name processorAdapter",
		"set exist/xquery/builtin-modules/module[last()]/parameter/#attribute/value org.exist.xquery.modules.xslfo.ApacheFopProcessorAdapter"
	],
	require => [
		Exec["build eXist"],
		File[$exist_data]
	]
}

augeas { "wrapper.conf":
        lens => "Properties.lns",
        incl => "$exist_home/tools/wrapper/conf/wrapper.conf",
        context => "/files$exist_home/tools/wrapper/conf/wrapper.conf/",
        changes => [
                "set wrapper.pidfile $exist_home",
                "set wrapper.java.pidfile $exist_home"
        ],
        require => [
		File[$exist_home],
		Exec["build eXist"]
	]
}

file_line { "exist.sh piddir":
	match => '^PIDDIR="."$',
        line => "PIDDIR=$exist_home",
        path => "$exist_home/tools/wrapper/bin/exist.sh",
        require => [
                File[$exist_home],
                Exec["build eXist"]
        ]
}->
file_line { "exist.sh upstart":
	match => '^USE_UPSTART=$',
        line => "USE_UPSTART=true",
        path => "$exist_home/tools/wrapper/bin/exist.sh",
        require => [
                File[$exist_home]
        ]
}->
file_line { "exist.sh run_as":
	match => '^#RUN_AS_USER=$',
        line => "RUN_AS_USER=exist",
        path => "$exist_home/tools/wrapper/bin/exist.sh",
        require => [
		File[$exist_home],
		User["exist"]
        ]
}


