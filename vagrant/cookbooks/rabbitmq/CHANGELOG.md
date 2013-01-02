## v1.7.0:

* [COOK-1850] - oracle linux support
* [COOK-1873] - add `set_user_tag` action to `rabbitmq_user` LWRP
* [COOK-1878] - :immediately action causes clustering to fail
* [COOK-1888] - smartos support

## v1.6.4:

* [COOK-1684] - Unify behavior of debian and rhel clones in the rabbitmq cookbook
* [COOK-1724] - enable using the distro release of rabbitmq instead of the RabbitMQ.org version

## v1.6.2:

* [COOK-1552] - removed rogue single quote from rabbitmq ssl
  configuration

## v1.6.0:

* [COOK-1496] - explicitly include the apt recipe
* [COOK-1501] - Allow user to enable yum-based installation of
  rabbitmq via an attribute
* [COOK-1503] - Recipe to enable rabbitmq web management console

## v1.5.0:

This version requires apt cookbook v1.4.4 (reflected in metadata).

* [COOK-1216] - add amazon linux to RHELish platforms
* [COOK-1217] - specify version, for RHELish platforms
* [COOK-1219] - immediately restart service on config update
* [COOK-1317] - fix installation of old version from ubuntu APT repo
* [COOK-1331] - LWRP for enabling/disabling rabbitmq plugins
* [COOK-1386] - increment rabbitmq version to 2.8.4
* [COOK-1432] - resolve foodcritic warnings
* [COOK-1438] - add fedora to RHELish platforms

## v1.4.1:

* [COOK-1386] - Bumped version to 2.8.4
* rabbitmq::default now includes erlang::default

## v1.4.0:

* [COOK-911] - Auto clustering support

## v1.3.2:

* [COOK-585] - manage rabbitmq-server service
