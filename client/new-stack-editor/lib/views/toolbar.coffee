kd = require 'kd'
JView = require 'app/jview'


module.exports = class Toolbar extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'toolbar', options.cssClass
    data ?= { title: '...' }

    super options, data


  pistachio: ->
    '{h3{#(title)}}'

