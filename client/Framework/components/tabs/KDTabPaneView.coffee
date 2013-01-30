class KDTabPaneView extends KDView
  constructor:(options,data)->
    options = $.extend
      hiddenHandle : no      # yes or no
      name         : no      # a String
    ,options
    super options,data
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
    @getDomElement().removeClass("kdhiddentab").addClass("active")
    @active = yes
    @emit "KDTabPaneActive"

  hide:()->
    @getDomElement().removeClass("active").addClass("kdhiddentab")
    @active = no
    @emit "KDTabPaneInactive"

  viewAppended:()->
    {name} = @getOptions()
    @setClass "kdtabpaneview"# #{name or ''}" Why do we need something like crazy?
    super

  setTitle:(title)->
    @getDelegate().setPaneTitle @,title
    @setOption "name", name
    @name = title

  getHandle: ->
    @getDelegate().getHandleByPane @

  hideTabCloseIcon:()->
    @getDelegate().hideCloseIcon @
