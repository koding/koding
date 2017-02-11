kd = require 'kd'
Events = require '../events'
BaseView = require './baseview'
FlexSplit = require './flexsplit'


module.exports = class SideView extends BaseView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'side-view hidden', options.cssClass
    options.pinnable = yes
    options.closable = yes

    super options, data

    @on FlexSplit.EVENT_EXPAND,   @lazyBound 'setClass',   'expanded'
    @on FlexSplit.EVENT_COLLAPSE, @lazyBound 'unsetClass', 'expanded'
    @on FlexSplit.EVENT_HIDE,     @bound 'hide'


  viewAppended: ->

    super

    @_loaderView.destroy()

    for name, { view, controls = {} } of @getOption 'views'

      @wrapper.addSubView view

      view.on Events.LazyLoadStarted,  @lazyBound 'setClass',   'loading'
      view.on Events.LazyLoadFinished, @lazyBound 'unsetClass', 'loading'

      for control, generator of controls when controls
        @controls.addSubView generator()

      view.hide()

    @_createLoaderView()


  show: (viewName) ->

    super

    viewName ?= @getOption 'defaultView'

    for _view, item of @getOption 'views'

      if _view is viewName
        @title.updatePartial item.title
        @setClass item.cssClass
        item.view.show()

      else
        @unsetClass item.cssClass
        item.view.hide()


  toggle: (viewName) ->

    if @hasClass 'hidden'
    then @show viewName
    else @hide()

