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

  .describe 'outdir', 'specify the outdir'
  .string 'outdir'

  .describe 'thirdparty-dir', 'specify the thirdparty libs dir'
  .string 'thirdparty-dir'

  .describe 'assets-dir', 'specify the assets dir'
  .string 'assets-dir'

  .describe 'baseurl', 'specify the public folder that is relative to application\'s root'
  .string 'baseurl'

  .describe 'globals-file', 'specify the globals file that will be exposed as \'globals\''
  .string 'globals-file'

  .describe 'config-file', 'specify the client config file that was generated with \'./configure\''
  .string 'config-file'

  .describe 'watch-js', 'enable watch mode for scripts'
  .boolean 'watch-js'
  .default 'watch-js', false

  .describe 'watch-css', 'enable watch mode for styles'
  .boolean 'watch-css'
  .default 'watch-css', false

  .describe 'watch-sprites', 'enable watch mode for sprites'
  .boolean 'watch-sprites'
  .default 'watch-sprites', false

  .describe 'debug-js', 'enable source maps for scripts'
  .boolean 'debug-js'
  .default 'debug-js', false

  .describe 'debug-css', 'enable source maps for styles'
  .boolean 'debug-css'
  .default 'debug-css', false

  .describe 'minify-js', 'minify scripts'
  .boolean 'minify-js'
  .default 'minify-js', false

  .describe 'minify-css', 'minify styles'
  .boolean 'minify-css'
  .default 'minify-css', false

  .describe 'collapse-js', 'collapse require paths to save extra bytes'
  .boolean 'collapse-js'
  .default 'collapse-js', false

  .describe 'extract-js-sourcemaps', 'extract source maps in debug mode'
  .boolean 'extract-js-sourcemaps'
  .default 'extract-js-sourcemaps', false

  .describe 'rev-id', 'write outfiles into $outdir/$git-revision-id'
  .boolean 'rev-id'
  .default 'rev-id', true

  .describe 'notify', 'enable system notifications in watch mode'
  .boolean 'notify'
  .default 'notify', true

  .describe 'notify-sound', 'play audio with system notifications'
  .boolean 'notify-sound'
  .default 'notify-sound', false

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

  .describe 'verbose', 'make the operation more talkative'
  .boolean 'verbose'
  .default 'verbose', false


haydar = new Haydar yargs.argv
haydar.build()
