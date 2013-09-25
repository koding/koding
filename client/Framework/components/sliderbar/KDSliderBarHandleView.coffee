class KDSliderBarHandleView extends KDCustomHTMLView
  constructor:(options = {})->
    options.tagName   = "a"
    options.cssClass  = "handle"
    options.value    ?= 0
    options.draggable =
      axis            : "x"

    super options

  attachEvents:->
    {maxValue, minValue, width} = @parent.getOptions()
    value                       = @getOption "value"

    @on "DragStarted", ->
      value = @getOption "value"
    @on "DragInAction", ->
      relPos             = @dragState.position.relative.x
      valueChange        = ((maxValue - minValue) * relPos) / width
      @setValue value + valueChange
      @snap() if @parent.getOption "snapOnDrag"
    @on "DragFinished", ->
      @snap() if @parent.getOption "snap"
      if value isnt @getOption "value"
        @emit        "ValueChange"
        @parent.emit "ValueChange", @

  getPosition:->
    {maxValue, minValue} = @parent.getOptions()
    {value}              = @getOptions()
    sliderWidth          = @parent.getWidth()

    percentage = ((value - minValue) * 100) / (maxValue - minValue)
    position   = (sliderWidth / 100) * percentage
    return "#{position}px"


  setValue:(value)->
    {leftLimit, rightLimit} = @getOptions()

    value = Math.min value, rightLimit if typeof rightLimit is "number"
    value = Math.max value, leftLimit  if typeof leftLimit  is "number"

    @options.value = value

    @setX "#{@getPosition()}"
    @parent.drawBar() if @parent.getOption('drawBar')
    @parent.setLimits()
    @parent.emit "ValueChanged", value

  getSnappedValue:(value)->
    {interval}  = @parent.getOptions()
    {value}     = value or @getOptions()

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