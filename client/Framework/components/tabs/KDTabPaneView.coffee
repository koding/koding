class KDTabPaneView extends KDView
  constructor:(options = {},data)->

    options.hiddenHandle ?= no      # a Boolean
    options.name        or= ""      # a String
    defaultCssClass       = "kdtabpaneview kdhiddentab #{KD.utils.slugify(options.name.toLowerCase())} clearfix"
    options.cssClass      = KD.utils.curryCssClass defaultCssClass, options.cssClass

    super options, data

    @name = options.name

    @on "KDTabPaneActive",   @becameActive
    @on "KDTabPaneInactive", @becameInactive
    @on "KDTabPaneDestroy",  @aboutToBeDestroyed
    @on "KDTabPaneActive",   @bound "setMainView"

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
    {view} = @getOptions()
    return if @mainView or not view

    {itemClass, options, data} = view
    @mainView = @addSubView if itemClass then new itemClass options, data else view
    @emit "KDTabPaneLazyViewAdded", @mainView
    return @mainView

  getMainView:-> @mainView
