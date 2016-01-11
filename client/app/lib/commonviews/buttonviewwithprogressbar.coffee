kd                = require 'kd'
KDButtonView      = kd.ButtonView
KDProgressBarView = kd.ProgressBarView
KDLoaderView      = kd.LoaderView
KDCustomHTMLView  = kd.CustomHTMLView


module.exports = class ButtonViewWithProgressBar extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    o               = @getOptions()        or {}
    buttonOptions   = o.buttonOptions      or {}
    progressOptions = o.progressOptions    or {}
    loaderOptions   = o.loaderOptions      or {}

    @button = new KDButtonView buttonOptions
    @button.setCallback @bound 'handleCallback'

    @addSubView @button

    @progressBar = new KDProgressBarView progressOptions
    @loader      = new KDLoaderView loaderOptions

    @progressBar.hide()

    @progressBar.addSubView @loader, null, yes
    @addSubView @progressBar


  handleCallback: ->

    buttonOptions = @getOption 'buttonOptions' or {}
    buttonOptions.callback.call()  if buttonOptions.callback

    @startProgress()


  startProgress: ->

    @button.disable()
    @button.hide()

    @loader.show()
    @progressBar.show()


  resetProgress: ->

    @show()

    @loader.hide()
    @progressBar.hide()
    @updateProgress 0

    @button.enable()
    @button.show()


  updateProgress: (value, unit, label) ->

    @progressBar.updateBar value, unit, label
