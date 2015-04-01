# test

this folder contains browser automated tests that run on [selenium server](http://www.seleniumhq.org).

# quick start

Go to [client](../client) folder and run:

```sh
λ koding/client make test
```

This will configure your `nightwatch` environment, transpile coffee-scripts under `test/lib` directory into `test/build`, start [selenium-server,](./vendor) and run your tests in the correct order that they need to be run.

# configuration

In order to run tests written with [Nightwatch.js](http://nightwatchjs.org) framework, you need to generate a [configuration script.](http://nightwatchjs.org/guide#settings-file)

This file can be automatically generated with:

```sh
λ client/test make configure
```

or you can directly run the configuration tool itself:

```sh
λ client/test ./bin/cmd.coffee browser
```

Running any of those will write two files in `client` directory:

### client/.nightwatch.json

This is the configuration file expected by `nightwatch` and it is generated specifically for the platform (os) you are on.

By default configuration tool, uses [a blueprint file](bin/nightwatch-blueprint.json) for the defaults.

But you can overwrite [any key](http://nightwatchjs.org/guide#settings-file) from cli using [dot notation](https://github.com/bcoe/yargs#dot-notation):

```sh
λ client/test ./bin/cmd.coffee browser --selenium.port 5555
```

### client/.config.json

This file is also extended with a `test.url` key that you have specified.

Following is the help output of the configuration tool:

```
usage: coffee bin/cmd.coffee <command> [options]

Commands:
  browser    configure browser tests

Options:
  --help, -h        show this message                                                                                        
  --url             specify a url that koding webserver is running on
  --nightwatch      specify a nightwatch config blueprint file.
                    actual config file will be written to client/.nightwatch.json
  --start-selenium  if enabled starts a selenium server process [default: true]
```

# running tests

There is a handful of `Makefile` targets defined to make life easier:

Configure and write `client/.nightwatch.json` file:

```sh
λ client/test make configure
```

You can pass additional args that is expected by configuration tool (`bin/cmd.coffee`):

```sh
λ client/test TEST_EXTRAS=--no-start-selenium make configure
```

Transpile coffee files under `test/lib` into `test/build`:

```sh
λ client/test make compile
```

A complete build with configuration and transpilation:

```sh
λ client/test make build
```

Run tests in the correct order that they need to be run:

```sh
λ client/test make run
```

Build and run:

```sh
λ client/test make all
```

# running tests individually

You can run tests individually using either `test` or `run.sh` scripts, these scripts are same except that `test` retranspiles coffees before running:

Run `activity` suite tests:

```sh
λ client/test ./test activity
```

Run `activity/likeunlike` suite

```sh
λ client/test ./test activity likeunlike
```

# license

2015 Koding, Inc
