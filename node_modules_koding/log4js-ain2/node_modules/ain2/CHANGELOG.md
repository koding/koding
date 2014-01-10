# CHANGELOG

## v1.2.1

* Reusing socket to send messages over UDP (Carlos Brito Lage/cblage)

## v1.1.1

Bugfix release

* The logging to file function crashed on unsupported systems due to
  immediate execution



## v1.1.0

* Custom message composer

## v1.0.0

WARNING: This upgrade is not API compatible to previous version.

* Change the API to actually use JavaScript's new operator to create loggers

		var SysLogger = require('ain2');
		var logger = new SysLogger({ port : 514, tag : 'myTag' });

* If you want to have singleton logger, use 
    
		var logger = require('ain2').getInstance();

## v0.2.1

* Support for node v0.6.0 (Yoji Shidara/darashi)

## v0.2.0

* Support for unix sockets, for the 0.4.x branch of node (Parham Michael
  Ossareh/ossareh)

## v0.0.3

* Explicitly fall back to original `console` object to log send failures (Mark Wubben/novemberborn)
* Default hostname to machine name rather than localhost (Mark Wubben/novemberborn)
* Fixes to make jslint happy (Mark Wubben/novemberborn, Patrick
  Huesler/phuesler)
* Test server for local testing

## v0.0.2

* add support for custom host and port
