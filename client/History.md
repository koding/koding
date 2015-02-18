0.1.0 / 2015-02-14
==================

The primary goal of this release is browserify compatibility.

## commonjs migration

Up until now we were exposing classes with unique names into `window` object, so everything was accessible from everywhere. This release introduces commonjs/node.js style modularity and `require` is the only exported method now on. Every file is encapsulated in its own space and there is no possible way to access top-level scope without being explicit. (eg `window.xyz = 1`) 

This also requires a file to `require` its dependencies apparently.

## Framework

* `kd` is re-designed and re-listed on npm as `kd.js`. It is also added to `browser` field of `package.json` as `kd`, so you can `require('kd')` whenever it is needed.

* `KDView`, `KDObject` etc. are no more. `kd` [exports all of its classes and methods](https://github.com/tetsuo/kd/blob/1.0.1/lib/index.coffee) without the `KD` prefix now.

Example:

```js
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

* playground/test/docs folders were obsolete and removed.

## KD

Besides for being the framework itself, `KD` was also being extended in runtime in two separate occasions:

* As a globally accessible object, it was being extended with configuration stuff. See go-webserver entry html.
* And with `KD.extend` and `KD.utils.extend` it was possible mix-in new methods onto it. 

These two are separated. (See `globals` and `app/util`)

## bongo-client

(TODO)

## broker-client

(TODO)

## sinkrow (daisy, dash)

(TODO)

## kookies

(TODO)

## kite.js

(TODO)

## underscore -> lodash

(TODO)

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

