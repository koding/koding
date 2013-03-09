default[:lxc][:network][:netmask] = '255.255.248.0'
default[:lxc][:network][:network] = '172.16.0.0/21'
default[:lxc][:network][:dhcp_start] = '172.16.0.2'
default[:lxc][:network][:dhcp_end] = '172.16.7.254'
default[:lxc][:network][:bridge_ip] = '172.16.0.1'
default[:lxc][:network][:vmroot_ip] = '172.16.0.10'

#default[:apt][:source][:vagrant] = "http://ftp.halifax.rwth-aachen.de/ubuntu/"
default[:apt][:source][:vagrant] = "http://us-east-1.archive.ubuntu.com/ubuntu/"
default[:apt][:source][:regular] = "http://us-east-1.archive.ubuntu.com/ubuntu/"