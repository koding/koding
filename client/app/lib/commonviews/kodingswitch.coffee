$ = require 'jquery'
kd = require 'kd'
KDOnOffSwitch = kd.OnOffSwitch
module.exports = class KodingSwitch extends KDOnOffSwitch


  constructor: (options = {}, data) ->

    options.labels       or= ['', '']
    options.defaultValue  ?= off

    super options, data


  setDomElement: (cssClass) ->

    @domElement = $ "<div class='kdinput koding-on-off off #{cssClass}'><a href='#' class='knob' title='turn on'></a></div>"

  mouseDown: ->
    unless @getOption 'disabled'
      @setValue if @getValue() is on then off else on


  setOff: (wCallback = yes) ->

    return if not @getValue() and wCallback

    @$('input').attr 'checked', no
    @unsetClass 'on'
    @setClass   'off'
    @switchStateChanged() if wCallback

  setOn: (wCallback = yes) ->

    return if @getValue() and wCallback

    @$('input').attr 'checked', yes
    @unsetClass 'off'
    @setClass   'on'
    @switchStateChanged() if wCallback
