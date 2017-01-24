kd = require 'kd'
JView = require 'app/jview'

Events = require '../events'


module.exports = class Toolbar extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'toolbar', options.cssClass
    data ?= { title: '' }

    super options, data

    @actionButton = new kd.ButtonView
      cssClass : 'action-button solid green compact'
      title    : 'Initialize'
      icon     : yes
      callback : => @emit Events.InitializeRequested, @getData()

    @expandButton = new kd.ButtonView
      cssClass: 'expand'
      callback: ->
        kd.singletons.mainView.toggleSidebar()


  pistachio: ->
    '{h3{#(title)}} {div.controls{> @expandButton}} {{> @actionButton}}'
