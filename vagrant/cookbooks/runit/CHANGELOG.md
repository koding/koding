## v0.16.2:

* [COOK-1576] - Do not symlink /etc/init.d/servicename to /usr/bin/sv
  on debian
* [COOK-1960] - default_logger still looks for sv-service-log-run
  template
* [COOK-2035] - runit README change

## v0.16.0:

* [COOK-794] default logger and `no_log` for `runit_service`
  definition
* [COOK-1165] - restart functionality does not work right on Gentoo
  due to the wrong directory in the attributes
* [COOK-1440] - Delegate service control to normal user

## v0.15.0:

* [COOK-1008] - Added parameters for names of different templates in runit
