# thirdparty

# ace

version: 1.1.4 (or 1.1.3)

source: https://github.com/ajaxorg/ace-builds/tree/v1.1.4

We are loading a [concatenated file](./ace/_ace.js) which includes, [ace.js](./ace/ace.js), [ext-languge_tools.js](./ace/ext-language_tools.js) and one another file that I can't remember what it was now, must be one of the keybinding scripts.

# emmet

version: 1.3.0 (patched)

source: https://github.com/tetsuo/emmet/commit/f1315a91317b291971fe4fde0ee772cec387bbca

### compat notes

ace@1.1.4/ext-emmet is not compatible with recent versions of emmet since emmet is migrated to browserify all the way. c9 dudes released a [special dist](https://github.com/cloud9ide/emmet-core/blob/master/emmet.js) just for ace; but I didn't want to use this build because,

- bundled emmet release is from 2013
- underscore@1.3.3 is bundled within
- pollutes global space and stuff

So I had to dirty-hack [ext-emmet.js](./ace/ext-emmet.js) to be compatible with emmet@1.3.0.

Dirty-hack was changing all `emmet.require` statements to [exposed](https://github.com/tetsuo/emmet/blob/v1.3.0/lib/emmet.js#L273) module paths.

- changed `u.require('xyz')` statements to `u.xyz`
- changed `u.require('utils').replaceSubString` statement to `u.utils.common.replaceSubString`

Still [range.js](https://github.com/emmetio/emmet/blob/v1.3.0/lib/assets/range.js) was not exposed, so I had to fork emmet and [expose that too](https://github.com/tetsuo/emmet/commit/f1315a91317b291971fe4fde0ee772cec387bbca).

Then I [concatenated](./ace/_ext-emmet.js) emmet's minified snippets build (which includes emmet core, snippets and excludes caniuse db) with patched [ext-emmet](./ace/ext-emmet-compat.js).
