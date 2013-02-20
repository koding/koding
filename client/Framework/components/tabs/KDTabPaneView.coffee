class KDTabPaneView extends KDView
  constructor:(options = {},data)->

    options.hiddenHandle ?= no      # yes or no
    options.name        or= ""      # a String
    options.cssClass      = KD.utils.curryCssClass "kdtabpaneview kdhiddentab clearfix #{KD.utils.slugify(options.name.toLowerCase())}"

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

class KDTabHandleView extends KDView
  constructor:(options)->
    options = $.extend
      hidden  : no          # yes or no
      title   : "Title"     # a String
      pane    : null        # a KDTabPaneView instance
      view    : null        # a KDView instance to put in the tab handle
    ,options
    super options

  setDomElement:()->
    c = if @getOptions().hidden then "hidden" else ""
    @domElement = $ "<div class='kdtabhandle #{c}'>
                      <span class='close-tab'></span>
                    </div>"

  viewAppended:()->
    if (view = @getOptions().view)?
      @addSubView view
    else
      @setPartial @partial()

  partial:->
    $ "<b>#{@getOptions().title or 'Default Title'}</b>"

  makeActive:()->
    @getDomElement().addClass "active"

  makeInactive:()->
    @getDomElement().removeClass "active"

  setTitle:(title)->
    # @getDomElement().find("span.close-tab").css "color", @getDelegate().getDomElement().css "background-color"

  # viewAppended:()->
  #   log @getDelegate()

