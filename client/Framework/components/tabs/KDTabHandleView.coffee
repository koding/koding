class KDTabHandleView extends KDView
  constructor:(options = {})->
    options.hidden   ?= no        # yes or no
    options.title    ?= "Title"   # a String
    options.pane     ?= null      # a KDTabPaneView instance
    options.view     ?= null      # a KDView instance to put in the tab handle
    options.sortable ?= no        # yes or no

    if options.sortable
      options.draggable  = axis: "x"
      @dragStartPosX = null

    super options

    @on "DragStarted", (event, dragState) =>
      @handleDragStart event, dragState

    @on "DragInAction", (x, y) =>
      @handleDragInAction x, y

    @on "DragFinished", (event) =>
      @handleDragFinished event

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

  isHidden: ->
    @getOptions().hidden

  getWidth: ->
    @$().outerWidth(no) or 0

  cloneElement: (x) ->
    return if @$cloned

    {pane}   = @getOptions()
    tabView  = pane.getDelegate()
    holder   = tabView.tabHandleContainer
    @$cloned = @$().clone() 
    holder.$().append @$cloned
    @$cloned.css marginLeft: -(tabView.handles.length - @index) * @getWidth()
  
  updateClonedElementPosition: (x) ->
    @$cloned.css left: x

  reorderTabHandles: (x) ->
    dragDir = @dragState.direction
    width   = @getWidth()
    if dragDir.current.x is 'left'
      targetIndex = @index - 1
      targetDiff  = -(width * @draggedItemIndex - width * targetIndex - width / 2)
      if x < targetDiff
        @emit "HandleIndexHasChanged", @index, 'left'
        @index--
    else 
      targetIndex = @index + 1
      targetDiff  = width * targetIndex - width * @draggedItemIndex - width / 2
      if x > targetDiff
        @emit "HandleIndexHasChanged", @index, 'right'
        @index++
    
  handleDragStart: (event, dragState) ->
    {pane}            = @getOptions()
    tabView           = pane.getDelegate()
    {handles}         = tabView
    @index            = handles.indexOf @
    @draggedItemIndex = @index

  handleDragInAction: (x, y) ->
    return unless @dragIsAllowed
    return @$().css 'left': 0 if -(@draggedItemIndex * @getWidth()) > x

    @unsetClass 'first'
    @cloneElement x
    @$().css opacity: 0.01
    @updateClonedElementPosition x
    @reorderTabHandles x

  handleDragFinished: (event) ->
    return unless @$cloned

    @$cloned.remove() 
    @$().css { left: '', opacity: 1, marginLeft: '' }
    @$().css left: 0 if not @targetTabHandle and @draggedItemIndex is 0
    @targetTabHandle = null
    @$cloned   = null