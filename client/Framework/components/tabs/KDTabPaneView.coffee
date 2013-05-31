class KDTabPaneView extends KDView
  constructor:(options = {},data)->

    options.hiddenHandle ?= no      # a Boolean
    options.name        or= ""      # a String
    defaultCssClass       = "kdtabpaneview kdhiddentab #{KD.utils.slugify(options.name.toLowerCase())} clearfix"
    options.cssClass      = KD.utils.curryCssClass defaultCssClass, options.cssClass

    super options, data

    @name = options.name

    @on "KDTabPaneActive",        @becameActive
    @on "KDTabPaneInactive",      @becameInactive
    @on "KDTabPaneDestroy",       @aboutToBeDestroyed
    @on "KDTabPaneActive",        @bound "setMainView"
    @on "KDTabPaneLazyViewAdded", @bound "fireLazyCallback"

  becameActive: noop
  becameInactive: noop
  aboutToBeDestroyed: noop

  show:()->
    @unsetClass "kdhiddentab"
    @setClass "active"
    @active = yes
    @emit "KDTabPaneActive"

  hide:()->
    @unsetClass "active"
    @setClass "kdhiddentab"
    @active = no
    @emit "KDTabPaneInactive"

  setTitle:(title)->
    @getDelegate().setPaneTitle @,title
    # @setOption "name", name
    @name = title

  getHandle: ->
    @getDelegate().getHandleByPane @

  hideTabCloseIcon:()->
    @getDelegate().hideCloseIcon @

  setMainView:->
    {view, viewOptions} = @getOptions()
    return if @mainView

    if view instanceof KDView
      @mainView = @addSubView view
    else if viewOptions
      {viewClass, options, data} = viewOptions
      @mainView = @addSubView new viewClass options, data
    else
      return warn "probably you set a weird lazy view!"

    @emit "KDTabPaneLazyViewAdded", this, @mainView
    return @mainView

  getMainView:-> @mainView

  fireLazyCallback:(pane, view)->
    {viewOptions} = @getOptions()
    return  unless viewOptions
    {callback} = viewOptions
    return  unless callback
    callback.call this, pane, view
