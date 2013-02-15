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

  # viewAppended:()->
  #   log @getDelegate()

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

  getTargetTabHandle: (index, x) ->
    {pane}    = @getOptions()
    tabView   = pane.getDelegate()
    {handles} = tabView
    targetTabHandle = null 
    
    if @isDraggingToLeft 
      targetTabHandle = handles[index - 1] unless index is 0
    else 
      targetTabHandle = handles[index + 1] unless index is handles.length

    return targetTabHandle

  updateClonedElementPosition: (x) ->
    @$cloned.css left: if not @targetTabHandle then 0 else x

  reorderTabHandles: (x) ->
    
    targetTabHandle  = @targetTabHandle = @getTargetTabHandle @index, x
    
    if targetTabHandle 
      width = @getWidth()
      diff  = @passedHandleLength * width
      
      # log x, diff, width, @passedHandleLength, @index, diff + width / 2, @dragState.directionX
 
      # return

      if x > diff + width / 2 # dragging to right
        log "to right"
        @passedHandleLength++
        @index++
        @$().insertAfter @targetTabHandle.$()
      else if x < diff + width / 2 # dragging to left
        log "to left"
        @passedHandleLength--
        @index--
        @$().insertAfter @targetTabHandle.$()

  handleDragStart: (event, dragState) ->
    @dragStartPosX      = $(event.delegateTarget).offset().left
    {pane}              = @getOptions()
    tabView             = pane.getDelegate()
    {handles}           = tabView
    @index              = handles.indexOf @
    @draggedItemIndex   = @index
    @passedHandleLength = 0

  handleDragInAction: (x, y) ->
    
    return unless @dragIsAllowed
    
    @cloneElement x
    @isDraggingToLeft = x < 0 
    @$().css opacity: 0.01
    @updateClonedElementPosition x
    @reorderTabHandles x

  handleDragFinished: (event) ->
    
    return unless @$cloned
    
    @$cloned.remove() 
    @$().css { left: '', opacity: 1, marginLeft: '' }
    @$().insertBefore @targetTabHandle.domElement if @targetTabHandle
    @$().css left: 0 if not @targetTabHandle and @draggedItemIndex is 0
    @targetTabHandle = null
    @$cloned   = null
    @emit "HandleIndexHasChanged"