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

      view.on Events.LazyLoadStarted,  @lazyBound 'setClass',    'loading'
      view.on Events.LazyLoadFinished, @lazyBound 'unsetClass',  'loading'
      view.on Events.ExpandSideView,   @lazyBound 'setClass',   'expanded'
      view.on Events.CollapseSideView, @lazyBound 'unsetClass', 'expanded'

      for control, generator of controls when controls
        @controls.addSubView generator()

      view.hide()

    @_createLoaderView()


  show: (viewName, options = {}) ->

    super

    viewName ?= @getOption 'defaultView'

    for _view, item of @getOption 'views'

      if _view is viewName
        if item.title?
          @title.updatePartial item.title
          @title.show()
        else
          @title.hide()
        @setClass item.cssClass
        item.view.show()

      else
        @unsetClass item.cssClass
        item.view.hide()

    if options.expanded?
      if options.expanded
        do @expand
      else
        do @collapse


  toggle: (viewName) ->

    if @hasClass 'hidden'
    then @show viewName
    else @hide()


  hide: (internal = no) ->

    return  if internal is yes and @hasClass 'pinned'

    super

    kd.singletons.windowController.revertKeyView()
    @unsetClass 'pinned'


  expand: ->

    @emit FlexSplit.EVENT_EXPAND
    @emit Events.GotFocus
