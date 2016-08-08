Watcher [![GoDoc](https://godoc.org/github.com/canthefason/go-watcher?status.svg)](https://godoc.org/github.com/canthefason/go-watcher) [![Build Status](https://travis-ci.org/canthefason/go-watcher.svg?branch=master)](https://travis-ci.org/canthefason/go-watcher)
=======

Watcher is a command line tool inspired by [fresh](https://github.com/pilu/fresh) and used for watching .go file changes, and restarting the app in case of an update/delete/add operation.

Most of the existing file watchers have a configuration burden, and even though Go has a really short build time, this configuration burden makes your binaries really hard to run right away. With Watcher, we aimed simplicity in configuration, and tried to make it as simple as possible.

## Installation

  Get the package with:

  `go get github.com/canthefason/go-watcher`

  Install the binary under go/bin folder:

  `go install github.com/canthefason/go-watcher/cmd/watcher`

  After this step, please make sure that your go/bin folder is appended to PATH environment variable.

## Usage

  `cd /path/to/myapp`

Start watcher:

  `watcher`

Watcher works like your native package binary. You can pass all your existing package arguments to the Watcher, which really lowers the learning curve of the package, and makes it practical.

##### Current app usage
  `myapp -c config -p 7000 -h localhost`

##### With watcher
  `watcher -c config -p 7000 -h localhost`

As you can see nothing changed between these two calls. When you run the command, Watcher starts watching folders recursively, starting from the current working directory. It only watches .go and .tmpl files and ignores hidden folders and _test.go files.

##### Package dependency

By default Watcher recursively watches all files/folders under working directory. If you prefer to use it like `go run`, you can call watcher with -run flag anywhere you want (we assume that your GOPATH is properly set).

  `watcher -c config -run github.com/username/somerootpackagename`

For the cases where your main function is in another directory other than the dependant package, you can do this by passing a different package name to -watch parameter.

  `watcher -c config -run github.com/username/somerootpackagename -watch github.com/username`


##### Vendor directory
Since Globs and some optional folder arrays will make it harder to configure, we are not planning to have support for a configurable watched folder structure. Only configuration we have here is, by default we have excluded vendor/ folder from watched directories. If your intention is making some changes in place, you can set -watch-vendor flag as "true", and start watching vendor directory.

## Author

* [Can Yucel](http://canthefason.com)

## License

The MIT License (MIT) - see LICENSE.md for more details


