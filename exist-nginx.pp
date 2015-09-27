# Puppet manifest for proxying eXist with nginx

$nginx_config = "/etc/nginx"
$exist_service = "eXist-db"

package { "nginx":
	ensure => present
}

file { "${nginx_config}/sites-enabled/default":
	ensure => absent,
	notify => Service["nginx"]
}

file { "${nginx_config}/sites-available/exist.conf":
	ensure => present,
	content => '
server {
        listen       80;
        server_name  localhost;

        charset utf8;

	proxy_set_header    Host                    $host;
	proxy_set_header    X-Real-IP               $remote_addr;
	proxy_set_header    X-Forwarded-For         $proxy_add_x_forwarded_for;
	proxy_set_header    nginx-request-uri       $request_uri;

        location / {
            proxy_pass http://localhost:8080/exist/rest/db/;
        }
}
',
	require => Package["nginx"]
}

file { "${nginx_config}/sites-enabled/exist.conf":
	ensure => link,
	target => "${nginx_config}/sites-available/exist.conf",
	require => File["${nginx_config}/sites-available/exist.conf"],
	notify => Service["nginx"]
}

service { $exist_service:
	ensure => running
}

service { "nginx":
	ensure => running,
	require => Service[$exist_service]
}
