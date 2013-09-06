# example = new KDSliderBarView
#   cssClass   : 'my-cute-slider'
#   minValue   : 0
#   maxValue   : 200
#   interval   : 10
#   width      : 500
#   snap       : yes
#   snapOnDrag : no
#   drawBar    : yes - [0, 25, 50, 75, 100]
#   showLabels : yes 
#   handles    : [100, 60]

class KDSliderBarView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->

    options.cssClass    = KD.utils.curryCssClass "sliderbar-container", options.cssClass
    options.minValue   ?= 0
    options.maxValue   ?= 100
    options.interval   ?= no
    options.drawBar    ?= yes
    options.showLabels ?= yes
    options.snap       ?= yes
    options.snapOnDrag ?= no
    options.width     or= 300

    super options, data

    @handles            = []
    @labels             = []

  createHandles:->
    for value in @getOption "handles"
      @handles.push @addSubView handle = new KDSliderBarHandleView {value}
    sortRef = (a,b) ->
      return -1 if a.options.value < b.options.value
      return  1 if a.options.value > b.options.value
      return  0

    @handles.sort(sortRef)

  drawBar:->
    positions = []
    positions.push handle.getRelativeX() for handle in @handles

    len       = positions.length
    left      = (parseInt(positions.first) if len > 1) or 0
    right     = parseInt(positions.last)
    diff      = right - left

    unless @bar
      @addSubView @bar = new KDCustomHTMLView
        cssClass : "bar"

    @bar.setWidth diff
    @bar.setX "#{left}px"

  _ಠcreateLabel : (value) =>
    {maxValue, minValue, interval, showLabels} = @getOptions()

    pos = ((value - minValue) * 100) / (maxValue - minValue)
    @labels.push @addSubView label = new KDCustomHTMLView
      cssClass    : "sliderbar-label"
      partial     : "#{value}"
    label.setX "#{pos}%"

  addLabels:->
    {maxValue, minValue, interval, showLabels} = @getOptions()

    if Array.isArray showLabels
    then @_ಠcreateLabel value for value in showLabels
    else @_ಠcreateLabel value for value in [minValue..maxValue] by interval

  getValues:-> handle.getOptions().value for handle in @handles

  setLimits:->
    {maxValue, minValue, interval}      = @getOptions()

    if @handles.length is 1
      @handles.first.options.leftLimit  = minValue
      @handles.first.options.rightLimit = maxValue
    else
      for handle, i in @handles
        options            = handle.getOptions()
        options.leftLimit  = @handles[i-1]?.options.value + interval or minValue
        options.rightLimit = @handles[i+1]?.options.value - interval or maxValue

  attachEvents:->
    @on "click", (event) ->
      {maxValue, minValue} = @getOptions()
      sliderWidth          = @getWidth()
      clickedPos           = event.pageX - @getBounds().x
      clickedValue         = ((maxValue - minValue) * clickedPos) / sliderWidth + minValue
      snappedValue         = @handles.first.getSnappedValue value: clickedValue
      closestHandle        = null
      mindiff              = null

      for handle in @handles
        {value}            = handle.getOptions()
        diff               = Math.abs(clickedValue - value)
        if (diff < mindiff) or not mindiff
          mindiff          = diff
          closestHandle    = handle

      closestHandle.setValue snappedValue

  viewAppended:->
    @setWidth @getOption "width"
    @createHandles()
    @setLimits()
    @drawBar()   if @getOption('drawBar')
    @addLabels() if @getOption('showLabels')
    @attachEvents()
    window.asd = @

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
    @on "DragFinished", -> @snap() if @parent.getOption "snap"

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
    @emit "ValueChange"
      
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