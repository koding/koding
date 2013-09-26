class KDSliderBarHandleView extends KDCustomHTMLView
  constructor:(options = {})->
    options.tagName   = "a"
    options.cssClass  = "handle"
    options.value    ?= 0
    options.draggable =
      axis            : "x"

    super options

    @value = @getOption 'value'

  attachEvents:->
    {maxValue, minValue, width} = @parent.getOptions()
    currentValue = @value

    @on "DragStarted", ->
      currentValue = @value

    @on "DragInAction", ->
      relPos      = @dragState.position.relative.x
      valueChange = ((maxValue - minValue) * relPos) / width
      @setValue currentValue + valueChange
      @snap() if @parent.getOption "snapOnDrag"

    @on "DragFinished", ->
      @snap() if @parent.getOption "snap"
      if currentValue isnt @value
        @emit        "ValueChange"
        @parent.emit "ValueChange", this

  getPosition:->
    {maxValue, minValue} = @parent.getOptions()
    sliderWidth          = @parent.getWidth()

    percentage = ((@value - minValue) * 100) / (maxValue - minValue)
    position   = (sliderWidth / 100) * percentage
    return "#{position}px"

  setValue:(value)->
    {leftLimit, rightLimit} = @getOptions()

    value = Math.min value, rightLimit if typeof rightLimit is "number"
    value = Math.max value, leftLimit  if typeof leftLimit  is "number"

    @value = value

    @setX "#{@getPosition()}"
    @parent.drawBar() if @parent.getOption('drawBar')
    @parent.setLimits()
    @parent.emit "ValueChanged", @value

  getSnappedValue:(value)->
    {interval} = @parent.getOptions()
    value    or= @value

    if interval
      mod = value % interval
      mid = interval / 2

      return value = switch
        when mod <= mid then value - mod
        when mod >  mid then value + (interval - mod)
        else value

  snap:->
    {interval}  = @parent.getOptions()
    value       = @getSnappedValue()

    if interval and @parent.getOption "snap"
      @setValue value
      @parent.drawBar() if @parent.getOption('drawBar')

  viewAppended:->
    @setX "#{@getPosition()}"
    @attachEvents()
    @snap() if @parent.getOption "snap"
