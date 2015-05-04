# Puppet manifest for proxying eXist with nginx

$nginx_config = "/etc/nginx/nginx.conf"
$exist_service = "eXist-db"

package { "nginx":
	ensure => present
}

file { $nginx_config:
	ensure => present,
	content => '
user  nginx;
worker_processes  1;
error_log  /var/log/nginx/error.log;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  \'$remote_addr - $remote_user [$time_local] "$request" \'
                      \'$status $body_bytes_sent "$http_referer" \'
                      \'"$http_user_agent" "$http_x_forwarded_for"\';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;

    proxy_set_header    Host                    $host;
    proxy_set_header    X-Real-IP               $remote_addr;
    proxy_set_header    X-Forwarded-For         $proxy_add_x_forwarded_for;
    proxy_set_header    nginx-request-uri       $request_uri;

    server {
        listen       80;
        server_name  localhost;

        charset utf8;

        access_log  /var/log/nginx/host.access.log  main;

        location / {
            proxy_pass http://localhost:8080/exist/rest/db/;
        }

    }

}
',
	require => Package["nginx"]
}

service { $exist_service:
	ensure => running
}

service { "nginx":
	ensure => running,
	require => [
		File[$nginx_config],
		Service[$exist_service]
	]
}