kd = require 'kd'
JView = require 'app/jview'


module.exports = class Statusbar extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'statusbar', options.cssClass
    data ?= { row: 1, column: 1, title: 'Loading...' }

    super options, data


  pistachio: ->
    '{h3{#(title)}} <span>Line {{#(row)}}, Column {{#(column)}}</span>'
