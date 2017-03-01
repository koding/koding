kd = require 'kd'
JView = require 'app/jview'


module.exports = class Statusbar extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'statusbar', options.cssClass
    data ?= { row: 1, column: 1, title: 'Loading...' }

    super options, data

    @switchButton = new kd.CustomHTMLView
      partial: 'USE OLD STACK EDITOR'
      cssClass: 'old-stack-editor'
      click: ->
        kd.singletons.mainController.useNewStackEditor no


  pistachio: ->
    '{h3{#(title)}} <span>Line {{#(row)}}, Column {{#(column)}}</span> {{> @switchButton}}'
