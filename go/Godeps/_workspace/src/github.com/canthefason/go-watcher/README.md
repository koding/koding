Watcher [![GoDoc](https://godoc.org/github.com/canthefason/go-watcher?status.svg)](https://godoc.org/github.com/canthefason/go-watcher) [![Build Status](https://travis-ci.org/canthefason/go-watcher.svg?branch=master)](https://travis-ci.org/canthefason/go-watcher)
=======

Watcher is a command line tool inspired by [fresh](https://github.com/pilu/fresh) and used for watching .go file changes, and restarting the app in case of an update/delete/add operation.

File change event listening infrastructure depends on stable version (.v1) of [fsnotify](https://github.com/go-fsnotify/fsnotify)

## Installation

  Get the package with:

  `go get github.com/canthefason/go-watcher`

  Install the binary under go/bin folder:

  `go install github.com/canthefason/go-watcher/cmd/watcher`

  If not added please append your go/bin folder to PATH environment variable.

## Usage

  `cd /path/to/myapp`

Start watcher:

  `watcher`

Watcher works like your native binary package. You can pass all the arguments that you are currently using.

##### Current app usage
  `myapp -c config -p 7000 -h localhost`

##### With watcher
  `watcher -c config -p 7000 -h localhost`

When you run the command it starts watching folders recursively, starting from the current working directory. It only watches .go and .tmpl files and ignores hidden folders.

##### Package dependency
  `watcher -c config -run github.com/username/somerootpackagename`

When your GOPATH is set, you can run your apps via their package names with -run parameter. By default it watches the underlying folder with subfolders.

  `watcher -c config -run github.com/username/somerootpackagename -watch github.com/username`

For the cases where your app depends on a few packages that are still in development, and you want to watch all the changes including those packages, you can pass a different package name for watching with -watch parameter.

Micro management of the watched packages are not supported yet. So you cannot exclude any folders.

## Author

* [Can Yucel](http://canthefason.com)

## License

The MIT License (MIT) - see LICENSE.md for more details


