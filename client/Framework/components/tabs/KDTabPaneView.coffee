class KDTabPaneView extends KDView
  constructor:(options = {},data)->
    
    options.hiddenHandle ?= no      # yes or no
    options.name        or= ""      # a String
    options.cssClass      = KD.utils.curryCssClass "kdtabpaneview kdhiddentab clearfix #{options.name}"

    super options, data
    
    @name = options.name
    @setClass "clearfix"
    @setHeight @$().parent().height()

    @on "KDTabPaneActive"   , @becameActive
    @on "KDTabPaneInactive" , @becameInactive
    @on "KDTabPaneDestroy"  , @aboutToBeDestroyed

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
    @setOption "name", name
    @name = title

  getHandle: ->
    @getDelegate().getHandleByPane @

  hideTabCloseIcon:()->
    @getDelegate().hideCloseIcon @
