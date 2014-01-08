stylus = require 'stylus'
node = stylus.nodes
sprite = require('../')
str = require('fs').readFileSync(__dirname + '/sprite.styl', 'utf8')

###
stylus(str)
  .set('filename', __dirname + '/sprite.styl')
  .define('sprite', sprite.stylus())
  .render (err, css) ->
    console.log err, css

###

sprite.stylus {path: "./images", watch: true }, (err, helper) ->
  output = ->
    stylus(str)
      .set('filename', __dirname + '/sprite.styl')
      .define('sprite', helper.fn)
      .render (err, css) ->
        console.log err if err
        console.log css
  output()
  helper.on "update", output
  console.log "watching for file changes in './images' ..."