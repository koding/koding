## v1.1.2:

* [COOK-1766] - Nginx Source Recipe Rebuilding Source at Every Run
* [COOK-1910] - Add IPv6 module
* [COOK-1966] - nginx cookbook should let you set `gzip_vary` and `gzip_buffers` in  nginx.conf
* [COOK-1969]- - nginx::passenger module not included due to use of symbolized `:nginx_configure_flags`
* [COOK-1971] - Template passenger.conf.erb configures key `passenger_max_pool_size` 2 times
* [COOK-1972] - nginx::source compile_nginx_source reports success in spite of failed compilation
* [COOK-1975] - nginx::passenger requires rake gem
* [COOK-1979] - Passenger module requires curl-dev(el)
* [COOK-2080] - Restart nginx on source compilation

## v1.1.0:

* [COOK-1263] - Nginx log (and possibly other) directory creations should be recursive
* [COOK-1515] - move creation of `node['nginx']['dir']` out of commons.rb
* [COOK-1523] - nginx `http_geoip_module` requires libtoolize
* [COOK-1524] - nginx checksums are md5
* [COOK-1641] - add "use", "`multi_accept`" and
  "`worker_rlimit_nofile`" to nginx cookbook
* [COOK-1683] - Nginx fails Windows nodes just by being required in
  metadata
* [COOK-1735] - Support Amazon Linux in nginx::source recipe
* [COOK-1753] - Add ability for nginx::passenger recipe to configure
  more Passenger global settings
* [COOK-1754] - Allow group to be set in nginx.conf file
* [COOK-1770] - nginx cookbook fails on servers that don't have a
  "cpu" attribute
* [COOK-1781] - Use 'sv' to reload nginx when using runit
* [COOK-1789] - stop depending on bluepill, runit and yum. they are
  not required by nginx cookbook
* [COOK-1791] - add name attribute to metadata
* [COOK-1837] - nginx::passenger doesn't work on debian family
* [COOK-1956] - update naxsi version due to incompatibility with newer
  nginx

## v1.0.2:

* [COOK-1636] - relax the version constraint on ohai

## v1.0.0:

* [COOK-913] - defaults for gzip cause warning on service restart
* [COOK-1020] - duplicate MIME type
* [COOK-1269] - add passenger module support through new recipe
* [COOK-1306] - increment nginx version to 1.2 (now 1.2.3)
* [COOK-1316] - default site should not always be enabled
* [COOK-1417] - resolve errors preventing build from source
* [COOK-1483] - source prefix attribute has no effect
* [COOK-1484] - source relies on /etc/sysconfig
* [COOK-1511] - add support for naxsi module
* [COOK-1525] - nginx source is downloaded every time
* [COOK-1526] - nginx_site does not remove sites
* [COOK-1527] - add `http_echo_module` recipe

## v0.101.6:

Erroneous cookbook upload due to timeout.

Version #'s are cheap.

## v0.101.4:

* [COOK-1280] - Improve RHEL family support and fix ohai_plugins
 recipe bug
* [COOK-1194] - allow installation method via attribute
* [COOK-458] - fix duplicate nginx processes

## v0.101.2:

* [COOK-1211] - include the default attributes explicitly so version
is available.

## v0.101.0:

**Attribute Change**: `node['nginx']['url']` -> `node['nginx']['source']['url']`; see the README.md.

* [COOK-1115] - daemonize when using init script
* [COOK-477] - module compilation support in nginx::source

## v0.100.4:

* [COOK-1126] - source version bump to 1.0.14

## v0.100.2:

* [COOK-1053] - Add :url attribute to nginx cookbook

## v0.100.0:

* [COOK-818] - add "application/json" per RFC.
* [COOK-870] - bluepill init style support
* [COOK-957] - Compress application/javascript.
* [COOK-981] - Add reload support to NGINX service

## v0.99.2:

* [COOK-809] - attribute to disable access logging
* [COOK-772] - update nginx download source location
