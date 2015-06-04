kd                = require 'kd'
KDButtonView      = kd.ButtonView
KDProgressBarView = kd.ProgressBarView
KDLoaderView      = kd.LoaderView
KDCustomHTMLView  = kd.CustomHTMLView


module.exports = class ButtonViewWithProgressBar extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    super options, data

    o               = @getOptions() or {}
    buttonOptions   = o.button      or {}
    progressOptions = o.progress    or {}
    loaderOptions   = o.loader      or {}

    progressOptions.cssClass = kd.utils.curry 'hidden', progressOptions.cssClass

    @button = new KDButtonView buttonOptions

    @button.click = (event) =>
      KDButtonView::click.call @button, event
      @startProgress()

    @addSubView @button

    @progressBar = new KDProgressBarView progressOptions
    @loader      = new KDLoaderView loaderOptions

    @progressBar.addSubView @loader, null, yes
    @addSubView @progressBar


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


  updateProgress: ->

    KDProgressBarView::updateBar.apply @progressBar, arguments

