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

    @listenTo
      KDEventTypes        : [ eventType : "KDTabPaneActive" ]
      listenedToInstance  : @
      callback            : @becameActive
    @listenTo
      KDEventTypes        : [ eventType : "KDTabPaneInactive" ]
      listenedToInstance  : @
      callback            : @becameInactive
    @listenTo
      KDEventTypes        : [ eventType : "KDTabPaneDestroy" ]
      listenedToInstance  : @
      callback            : @aboutToBeDestroyed

  becameActive: noop
  becameInactive: noop
  aboutToBeDestroyed: noop

  show:()->
    @getDomElement().removeClass("kdhiddentab").addClass("active")
    @active = yes
    @handleEvent type : "KDTabPaneActive"
    
  hide:()->
    @getDomElement().removeClass("active").addClass("kdhiddentab")
    @active = no
    @handleEvent type : "KDTabPaneInactive"
  
  viewAppended:()->
    {name} = @getOptions()
    @setClass "kdtabpaneview #{name or ''}"
    super

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
    
