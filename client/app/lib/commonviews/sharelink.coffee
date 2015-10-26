kd = require 'kd'
KDButtonView = kd.ButtonView
nick = require '../util/nick'


module.exports = class ShareLink extends KDButtonView
  constructor: (options = {}, data) ->
    options.cssClass      = kd.utils.curry "share-icon #{options.provider}", options.cssClass
    options.partial       = """<span class="icon"></span>"""
    options.iconOnly     ?= yes
    options.trackingName ?= ""
    super options, data

  click: (event) ->
    kd.utils.stopDOMEvent event

    {provider, trackingName} = @getOptions()

    global.open(
      @getUrl(),
      "#{provider}-share-dialog",
      "width=626,height=436,left=#{Math.floor (global.screen.width/2) - (500/2)},top=#{Math.floor (global.screen.height/2) - (350/2)}"
    )
