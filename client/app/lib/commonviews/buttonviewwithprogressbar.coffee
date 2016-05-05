kd                = require 'kd'
KDButtonView      = kd.ButtonView
KDProgressBarView = kd.ProgressBarView
KDCustomHTMLView  = kd.CustomHTMLView


module.exports = class ButtonViewWithProgressBar extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    o                = @getOptions()     or {}
    o.startProgress ?= yes

    buttonOptions    = o.buttonOptions   or {}
    progressOptions  = o.progressOptions or {}
    loaderOptions    = o.loaderOptions   or {}

    buttonOptions.cb         = buttonOptions.callback
    buttonOptions.callback   = @bound 'handleCallback'
    progressOptions.cssClass = kd.utils.curry 'hidden', progressOptions.cssClass

    @addSubView @button      = new KDButtonView buttonOptions
    @addSubView @progressBar = new KDProgressBarView progressOptions


  handleCallback: ->

    buttonOptions = @getOption 'buttonOptions' or {}
    buttonOptions.cb?.call()

    @startProgress()  if @getOption 'startProgress'


  startProgress: ->

    @button.disable()
    @progressBar.show()


  resetProgress: ->

    @show()
    @progressBar.hide()
    @updateProgress 0
    @button.enable()


  updateProgress: (value, unit, label) ->

    @progressBar.updateBar value, unit, label
