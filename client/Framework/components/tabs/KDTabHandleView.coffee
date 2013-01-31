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

  isHidden: ->
    @getOptions().hidden

  getWidth: ->
    @$().outerWidth(no) or 0