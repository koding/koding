# client

this is the root project and contains all modules which you need to build [koding](http://koding.com) frontend.

# install

```
npm install
```

This will also install dependencies of [builder](./builder) and [landing](./landing).

# configuration

A `./configure` step is required to write git revision id into `.config.json` file that `builder` depends on.

```sh
λ dev/koding HOST=xyz.koding.io PORT=8090 make configure
```

(If you are using [remotepot](https://github.com/koding/tools/tree/master/remotepot) in development, make sure you have run `./configure` in same commit both on your localhost and on your vm.)

# quick start

Following will start the koding application and client builder in watch mode:

```sh
λ dev/koding make run
```

Or, if you haven't run configure yet:

```sh
λ dev/koding HOST=xyz.koding.io PORT=8090 make all
```

You can also `./run backend` only which is the prefered way to develop frontend:

```sh
λ dev/koding make backend
λ dev/koding make -C client all
```

# development

Frontend application is being built by [builder](./builder) and it has a bunch of options that you won't probably need to alter since the most general purpose combinations are pre-configured in `Makefile`.

Watch scripts, styles & sprites and recompile/transpile upon changes:

```sh
λ koding/client make watch
```

Creating source maps is kinda expensive, so they are disabled by default.

If you don't mind slower builds in watch mode and need source maps, try this:

```sh
λ koding/client EXTRAS="--debug-js --debug-css" make watch
```

If you want to have your source maps inlined, but no watch mode:

```sh
λ koding/client make debug
```

Minify scripts and styles:

```sh
λ koding/client make minify
```

Minify scripts and styles, but write source maps of scripts to an external `.map` file for production:

```sh
λ koding/client make production
```

Vanilla:

```sh
λ koding/client make vanilla
```

Build [landing](./landing):

```
λ koding/client make landing
```

And finally there are `make all` and `make dist` which are simply aliases for `make landing development` and `make landing production` respectively.

You can also pass additional [builder](./builder) arguments using `EXTRAS` variable.

Start in debug mode omitting scripts:

```
λ dev/koding/client EXTRAS=--no-scripts make debug
```

Start in watch mode, but do no watch sprites and play sound with notifications:

```
λ dev/koding/client EXTRAS="--no-watch-sprites --notify-sound" make watch
```

# code organization

A module's directory tree looks like this:

```
├── Readme.md
├── bant.json
└── lib
    ├── styl
    │   ├── x.styl
    ├── sprites
    │   ├── 1x
    │   │   ├── x.png
    │   ├── 2x
    │   │   ├── x.png
    ├── x.coffee
```

# testing

To run browser tests, type:

```sh
λ koding/client npm test
```

or

```sh
λ koding/client make test
```

If you have a [Selenium](http://www.seleniumhq.org) server started already on your machine, type:

```sh
λ koding/client TEST_EXTRAS=--no-start-selenium make test
```

If your web server is not running on localhost, you can specify its url like this:

```sh
λ koding/client TEST_EXTRAS="--url http://xyz.koding.io:8090" make test
```

Read more about browser tests and test configuration cli [here.](./test)

# bant.json

A module folder _must_ contain this file in order to get built. You can read more about the `bant` spec here in this nice project site of [bantjs](https://github.com/bantjs).

Our special purpose fields are;

* `routes` to define route maps
* `sprites` to define sprite folders
* `styles` to define style folders

# globals.coffee

This file is a some sort of virtual module that is exposed as `globals` which you can `require` in run-time.

```coffee
globals = require 'globals'
```

You can also extend this object from a `bant.json` file by adding a `globals` field in it, which is the prefered method if you know only this module going to need that particular data.

# .config.json

This file is generated with `./configure` with an initial value of a git revision id. It is crucial that both `builder` and web servers have the same value of it.

If this file does not exist, builder will re-create it, but with an hardcoded revision id and things will mess up. That's why `.config.json` _must_ be generated with `./configure`.

This file is also being used to cache models schema, so subsequent `make`s won't call bongo api again if there is already a `schema` field exists in this file.

# thirdparty

[thirdparty](./thirdparty) folder contains third-party dependencies that are not possible to install using [npm](http://npmjs.org).

For future dependencies; please keep in mind that this folder should only be used as the last resort. If the library that you want to install doesn't exist in npm registry, and if it is not a requirejs module or something; please port it to commonjs and publish it on npm.

# assets

[assets](./assets) folder is copied into public directory of our application. So whatever you want to keep in there you can drop it in here and it will be automatically copied. Black magic.

# landing

[landing](./landing) is not a module, it is a giant octopus with 7 hearts and 32 tentacles and a detachable penis.

# license

2015 Koding, Inc
