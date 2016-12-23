0.1.0 / 2015-02-14
==================

The primary goal of this release is browserify compatibility.

## commonjs migration

Up until now we were exposing classes with unique names into `window` object, so everything was accessible from everywhere. This release introduces commonjs/node.js style modularity and `require` is the only exported method now on. Every file is encapsulated in its own space and there is no possible way to access top-level scope without being explicit. (eg `window.xyz = 1`)

This also requires a file to `require` its dependencies apparently.

## Accessing KD -> kd

`window.KD` global that we used for almost anything is now gone. But we have a shortcut for it in `dev/sandbox` environments which is `window._kd` _(only for testing purposes, i.e. only for using from the browser console)_ __(should not be used in the code)__. On `prod/latest` environments you can use `require('kd')` to access the global. Some of them old `KD` properties are moved under `require('globals')` such as `config`, `apps`, `appClasses` etc.

## Framework

* `kd` is re-designed and re-listed on npm as `kd.js`. It is also added to `browser` field of `package.json` as `kd`, so you can `require('kd')` whenever it is needed.

* `KDView`, `KDObject` etc. are no more. `kd` [exports all of its classes and methods](https://github.com/tetsuo/kd/blob/1.0.1/lib/index.coffee) without the `KD` prefix now.

Example:

```coffeescript
kd = require 'kd'

class X extends kd.View
```

- Some of its dependencies were missing on npm, they are also ported and listed:

  - https://www.npmjs.com/package/kd-dom
  - https://www.npmjs.com/package/kd-polyfills
  - https://www.npmjs.com/package/kd-shim-canvas-loader
  - https://www.npmjs.com/package/kd-shim-inflector
  - https://www.npmjs.com/package/kd-shim-mutation-summary
  - https://www.npmjs.com/package/kd-shim-jspath

* [Styl entry file](https://github.com/tetsuo/kd/blob/1.0.1/lib/styles/index.styl) is being transpiled with `--include-css` now on.

* `playground` folder is gone. Typing `make example` starts a simple development server and recompiles files upon changes in `example` folder.

* `test` & `docs` became obsolete and removed.

* `KD.EventEmitter.Wildcard` is changed to `kd.EventEmitterWildcard`

## Developing framework

__IMPORTANT :__ *currently only possible with node v0.12.0*

We were using `gulp` to watch for changes in Framework submodule. Since this submodule is removed, this mechanism is changed dramatically.

So in order to watch for changes in framework you have two options:

But before that, you need to clone [kd.js](https://github.com/tetsuo/kd) repo separately.

#### watching dist files

To watch `lib` folder and build a standalone umd package into `dist` folder, you type `make development-dist`. But the thing is we are not bundling `kd.js` as an umd package in koding browserify bundle, so this won't help much.

#### recompiling coffees and npm link

Second option and working one in our situation is `make development` and requires some explanation:

Each file in `kd.js/lib` folder is individualy compiled with coffee-script compiler into `kd.js/build` folder before publishing to npm. So what you see in `dist` folder is a browserify bundle and it doesn't exists in npm, but in `build` folder there are raw js files and these are the files that we need to watch.

When you do `require 'kd'` browserify resolves this to `node_modules/kd.js/build/lib/index.js`, and if you change this file you will see watcher will be triggered and recompile stuff.

But we don't really want to make changes in node_modules folder since it is not a git repo.

What we need is to link `kd.js` working dir into `client`.

Long story short this is how you do it:

Clone `kd.js` first:

```sh
git clone git@github.com:tetsuo/kd.git
```

Install its dependencies:

```sh
npm install
```

And [link](https://docs.npmjs.com/cli/link) it:

```sh
npm link
```

Go back to `koding/client` folder, and remove `kd.js` in `node_modules`:

```sh
rm -fr node_modules/kd.js
```

And link it:

```sh
npm link kd.js
```

Now when you take a look at `node_modules/kd.js` folder, you will see it's just a symlink to your previously cloned directory.

Start for listening changes in `koding/client`:

```sh
make scripts
```

This will start watching your symlinked clone, change to your clone dir again, and type in the holy letters:

```sh
make development
```

That's it. Now whenever you change a file in `lib` directory in your clone, its js equivalent is gonna be recompiled in `build` folder which is linked to `koding/client`.


## KD

Besides for being the framework itself, `KD` was also being extended in runtime in two separate occasions:

* As a globally accessible object, it was being extended with configuration stuff.
* And with `KD.extend` and `KD.utils.extend` it was possible mix-in new methods onto it.

These two are separated. (See `globals` and `app/util`)

## bongo-client

It was a module under `node_modules_koding` now it is in its separate package at github.com/koding/bongo-client

## sinkrow (daisy, dash)

It was a module under `node_modules_koding` now it is in its separate package at github.com/koding/sinkrow , we didn't name this, this was already there and used by `Bongo` and we just separated it since it is not wise to require bongo to only use `dash` or `daisy` methods.

## kookies

`Cookies` mini library we used became `kookies`, I don't remember why we changed the name. - SY

## kite.js

(TODO)

## underscore -> lodash

We use `lodash` as underscore, because we mapped it in `package.json` where you ask for underscore it gives you lodash. The reason is that we already used `underscore` in many places and instead of refactoring those we mapped the package. As for why we decided for `lodash` same api and more, better maintained, faster etc. Google it for more.

## jquery.timeago -> timeago

(TODO)

## sockjs-client

(TODO)

## htmlencode, Encoder

(TODO)

## bant

(TODO)

## rewritify

(TODO)

## pistachioify

(TODO)

## execution order

(TODO)

## util folder

(TODO)

## pre-factor-bundle fuckups

(TODO)

## lowercase dir names

(TODO)

## router, lazyrouter

(TODO)

## self-invoking methods, mq

(TODO)

## remote -> remote.getInstance

(TODO)

## core-main -> app (& factor-bundle fuckups)

(TODO)

## bugs, and not tested stuff

(TODO)

## gulp

(TODO)

## node_modules_koding bongo

(TODO)

## assets

(TODO)

## thirdparty folder

(TODO)

## config files

(TODO)

## appcontroller -> index

(TODO)

## ace requirejs

(TODO)

## getscript

(TODO)

## package.json npm

(TODO)

## package.json browser field

(TODO)

## globals

(TODO)

## window -> global

(TODO)

## registerSingleton

(TODO)
