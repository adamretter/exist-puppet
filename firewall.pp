include ufw

###
# Set the firewall basics
###

ufw::allow { "allow-ssh-from-all":
        port => 22,
}

ufw::allow { "web-from-all":
	port => 80,
}

