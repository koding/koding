kd = require 'kd'



module.exports = class Statusbar extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'statusbar', options.cssClass
    data ?= { row: 1, column: 1, title: 'Loading...' }

    super options, data

    @switchButton = new kd.CustomHTMLView
      partial: 'USE OLD STACK EDITOR'
      cssClass: 'old-stack-editor'
      click: ->
        kd.singletons.mainController.useOldStackEditor yes


  pistachio: ->
    '{h3{#(title)}} <span>Line {{#(row)}}, Column {{#(column)}}</span> {{> @switchButton}}'
