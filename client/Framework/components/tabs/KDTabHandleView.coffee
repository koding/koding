class KDTabHandleView extends KDView

  constructor: (options = {}, data) ->

    options.hidden   ?= no        # yes or no
    options.title    ?= "Title"   # a String
    options.pane     ?= null      # a KDTabPaneView instance
    options.view     ?= null      # a KDView instance to put in the tab handle
    options.sortable ?= no        # yes or no
    options.closable ?= yes       # yes or no

    if options.sortable
      options.draggable  = axis: "x"
      @dragStartPosX = null

    super options, data

    @on "DragStarted", (event, dragState) =>
      @startedDragFromCloseElement = $(event.target).hasClass "close-tab"
      @handleDragStart event, dragState

    @on "DragInAction", (x, y) =>
      @dragIsAllowed = no if @startedDragFromCloseElement
      @handleDragInAction x, y

    @on "DragFinished", (event) =>
      @handleDragFinished event
      @getDelegate().showPaneByIndex @index

  setDomElement:(cssClass="")->
    {hidden, closable, tagName, title} = @getOptions()
    cssClass    = if hidden   then "#{cssClass} hidden" else cssClass
    closeHandle = if closable then "<span class='close-tab'></span>" else ""

    @domElement = $ "<#{tagName} title='#{title}' class='kdtabhandle #{cssClass}'>#{closeHandle}</#{tagName}>"

  viewAppended:->
    {view} = @getOptions()
    if view and view instanceof KDView
    then @addSubView view
    else @setPartial @partial()

  partial:-> "<b>#{@getOptions().title or 'Default Title'}</b>"

  makeActive:->
    @getDomElement().addClass "active"

  makeInactive:->
    @getDomElement().removeClass "active"

  setTitle:(title)->
    @setAttribute "title", title
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