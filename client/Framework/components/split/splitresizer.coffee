class KDSplitResizer extends KDView

  constructor:(options = {}, data)->

    @isVertical = options.type.toLowerCase() is "vertical"

    axis = if @isVertical then "x" else "y"

    options.draggable ?= { axis }

    super options, data

    {@panel0, @panel1} = @getOptions()

    @on "DragFinished", @dragFinished
    @on "DragInAction", @dragInAction
    @on "DragStarted", @dragStarted

  _setOffset:(offset)->
    offset = 0 if offset < 0
    if @isVertical then @$().css left : offset-5 else @$().css top : offset-5

  _getOffset:(offset)->
    if @isVertical then @getRelativeX() else @getRelativeY()

  _animateTo:(offset)->
    d = @parent.options.duration
    if @isVertical
      offset -= @getWidth() / 2
      @$().animate left : offset,d
    else
      offset -= @getHeight() / 2
      @$().animate top : offset,d

  dragFinished:(event, dragState)->

    @parent._resizeDidStop event

  dragStarted:(event, dragState)->

    @parent._resizeDidStart()
    @rOffset  = @_getOffset()
    @p0Size   = @panel0._getSize()
    @p1Size   = @panel1._getSize()
    @p1Offset = @panel1._getOffset()

  dragInAction:(x, y)->

    if @isVertical
      # check if views are fine with that
      p0WouldResize = @panel0._wouldResize x + @p0Size
      p1WouldResize = @panel1._wouldResize -x + @p1Size if p0WouldResize

      # see if they resize
      @dragIsAllowed = if p1WouldResize
        @panel0._setSize x + @p0Size
        @panel1._setSize -x + @p1Size
        yes
      else
        @_setOffset @panel1._getOffset()
        no

      # set the changed offset of second panel
      @panel1._setOffset x + @p1Offset if @dragIsAllowed

    else
      # check if views are fine with that
      p0WouldResize = @panel0._wouldResize y + @p0Size
      p1WouldResize = @panel1._wouldResize -y + @p1Size
      # see if they resize
      p0DidResize = if p0WouldResize and p1WouldResize then @panel0._setSize y + @p0Size else no
      p1DidResize = if p0WouldResize and p1WouldResize then @panel1._setSize -y + @p1Size else no
      # set the changed offset of second panel
      @panel1._setOffset y + @p1Offset if p0DidResize and p1DidResize
