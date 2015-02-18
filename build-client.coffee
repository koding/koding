#!/usr/bin/env coffee

{exec}            = require 'child_process'
argv              = require('minimist')(process.argv.slice(2))
sinkrow           = require 'sinkrow'

try
  KONFIG = JSON.parse(process.env.KONFIG_JSON)
catch error
  console.log "buildclient: Error when trying to parse 'KONFIG_JSON'"
  return

args =
  watchDuration : argv.watchDuration  or 5000
  watch         : argv.watch          or KONFIG.client.watch or false
  version       : argv.version        or KONFIG.version      or "0.0.1"
  sourceMapsUri : argv.sourceMapsUri  or KONFIG.client.runtimeOptions.sourceMapsUri or "koding.com/sourcemaps"
  verbose       : argv.verbose        or false

console.log "building client with options:", args

build = ->

  {daisy} = sinkrow

  queue = [
    ->
      exec 'cd client/landing && npm i', (err, stdout, stderr)->
        if err
        then console.error err
        else console.log "# LANDING PAGE DEPENDENCIES INSTALLED"
        queue.next()
    ,
    ->
      exec 'rm -rf client/landing/node_modules/gulp.spritesmith/node_modules/spritesmith/node_modules/canvassmith', (err)->
        if err
        then console.error err
        else console.log "# canvassmith removed ---"
        queue.next()
    ,
    ->
      exec "cd client/landing && gulp build-all-sites --koding-version=#{args.version}", (err, stdout, stderr)->
        if err
        then console.error err
        else console.log """
        # LANDING PAGE BUILT
         For further development of landing page, clone koding/landing and follow its readme.
        """
        queue.next()
    ,
    ->
      exec "rsync -av #{__dirname}/client/landing/static/a/ #{__dirname}/website/a/", (err, stdout, stderr)->
        if err
        then console.error err
        else console.log "# LANDING PAGE EXPORTED"
        queue.next()
    ,
    ->
        console.log "\n# EXTERNAL BUILDS FINISHED!\n"
        console.log """

          ########################################
          ########################################

          # FOR LANDING PAGE DEVELOPMENT PLEASE DO

          # for a build and watch system
          $ cd #{__dirname}/client/landing/site.landing/
          $ gulp --outputDir=#{__dirname}/website/a/site.landing/

          # for just build and quit
          $ cd #{__dirname}/client/landing/site.landing/
          $ gulp build --outputDir=#{__dirname}/website/a/site.landing/

          ########################################
          ########################################

          """
        queue.next()
  ]

  daisy queue, ->

build()
