#!/usr/bin/env coffee

Haydar = require '../index'

yargs = require 'yargs'

  .usage 'usage: $0 {options}'

  .help 'help'
  .version require('../package.json').version + '\n', 'version'
  
  .alias 'help', 'h'
  .alias 'version', 'V'
  .alias 'verbose', 'v'

  .describe 'help', 'show this message'
  .describe 'version', 'show version number'

  .describe 'use', 'a bant manifest file to require. files can be globs.'
  .string 'use'

  .describe 'basedir', 'specify the base dir for relative path resolution'
  .string 'basedir'

  .describe 'baseurl', 'specify the public folder that is relative to application\'s root'
  .string 'baseurl'

  .describe 'thirdparty-dir', 'specify the thirdparty libs dir'
  .string 'thirdparty-dir'

  .describe 'assets-dir', 'specify the assets dir'
  .string 'assets-dir'

  .describe 'globals-file', 'specify the globals file that will be exposed as \'globals\''
  .string 'globals-file'

  .describe 'config-file', 'specify the client config file that was generated with \'./configure\''
  .string 'config-file'

  .describe 'js-outfile', 'write js bundle to this file'
  .string 'js-outfile'

  .describe 'css-outdir', 'write css bundles to this dir'
  .string 'css-outdir'

  .describe 'assets-outdir', 'write assets to this dir'
  .string 'assets-outdir'

  .describe 'thirdparty-outdir', 'write thirdparty libs to this dir'
  .string 'thirdparty-outdir'

  .describe 'watch-js', 'enable watch mode for scripts'
  .boolean 'watch-js'
  .default 'watch-js', false

  .describe 'watch-css', 'enable watch mode for styles'
  .boolean 'watch-css'
  .default 'watch-css', false

  .describe 'debug-js', 'enable source maps for scripts'
  .boolean 'debug-js'
  .default 'debug-js', false

  .describe 'debug-css', 'enable source maps for styles'
  .boolean 'debug-css'
  .default 'debug-css', false

  .describe 'minify-js', 'minify scripts with uglifyjs'
  .boolean 'minify-js'
  .default 'minify-js', false

  .describe 'minify-css', 'minify styles with clean-css'
  .boolean 'minify-css'
  .default 'minify-css', false

  .describe 'scripts', 'build scripts'
  .boolean 'scripts'
  .default 'scripts', true

  .describe 'styles', 'build styles'
  .boolean 'styles'
  .default 'styles', true

  .describe 'sprites', 'build sprites'
  .boolean 'sprites'
  .default 'sprites', true

  .describe 'assets', 'copy assets'
  .boolean 'assets'
  .default 'assets', true

  .describe 'thirdparty', 'copy thirdparty'
  .boolean 'thirdparty'
  .default 'thirdparty', true

  .describe 'extract-js-sourcemaps', 'extract source maps in debug mode'
  .boolean 'extract-js-sourcemaps'
  .default 'extract-js-sourcemaps', false

  .describe 'rev-id', 'add revision id to output filenames'
  .boolean 'rev-id'
  .default 'rev-id', true

  .describe 'notify', 'disable system notifications in watch mode'
  .boolean 'notify'
  .default 'notify', false

  .describe 'verbose', 'make the operation more talkative'
  .boolean 'verbose'
  .default 'verbose', false


haydar = new Haydar yargs.argv
haydar.build()
