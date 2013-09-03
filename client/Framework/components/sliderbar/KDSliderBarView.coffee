class KDSliderBarView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->

    options.cssClass    = KD.utils.curryCssClass "sliderbar-container", options.cssClass
    options.minValue   ?= 0
    options.maxValue   ?= 100
    options.interval   ?= no
    options.drawBar    ?= yes
    options.showLabels ?= yes
    options.snap       ?= yes
    options.width     or= 300

    super options, data

    @handles            = []
    @labels             = []

  createHandles:->
    for value in @getOption "handles"
      @handles.push @addSubView handle = new KDSliderBarHandleView  {}, {value}

    sortRef = (a,b) ->
      return -1 if a.getData().value < b.getData().value
      return  1 if a.getData().value > b.getData().value
      return  0
    @handles.sort sortRef

  drawBar:->
    positions = []
    for handle in @handles
      positions.push handle.getRelativeX()

    len       =  positions.length
    left      = (parseInt(positions.first) if len>1) or 0
    right     =  parseInt(positions.last)
    diff      =  right - left

    unless @bar
      @addSubView @bar = new KDCustomHTMLView
        cssClass : "bar"

    @bar.setWidth diff
    @bar.setX "#{left}px"

  addLabels:->
    {maxValue, minValue, interval, showLabels} = @getOptions()

    createLabel = (value)=>
      pos = ((value-minValue)*100)/(maxValue-minValue)
      @labels.push @addSubView label = new KDCustomHTMLView
        cssClass    : "sliderbar-label"
        partial     : "#{value}"
      label.setX "#{pos}%"

    if Array.isArray showLabels
      for value in showLabels
        createLabel value
    else
      for value in [minValue..maxValue] by interval
        createLabel value

  getValues:->
    values = []
    for handle in @handles
      values.push handle.getData().value
    return values

  setLimits:->
    {maxValue, minValue, interval}      = @getOptions()

    if @handles.length is 1
      @handles.first.data.leftLimit     = minValue
      @handles.first.data.rightLimit    = maxValue
    else
      for handle in @handles
        i               = @handles.indexOf(handle)
        data            = handle.data

        data.leftLimit  = @handles[i-1]?.getData().value + interval or minValue
        data.rightLimit = @handles[i+1]?.getData().value - interval or maxValue

  attachEvents:->
    @on "click", (event)->
      {maxValue, minValue} = @getOptions()
      sliderWidth          = @getWidth()
      clickedPos           = event.pageX - @getBounds().x
      clickedValue         = ((maxValue-minValue)*clickedPos)/sliderWidth + minValue
      snappedValue         = @handles.first.getSnappedValue value : clickedValue
      closestHandle        = undefined
      mindiff              = undefined

      for handle in @handles
        value   = handle.getData().value
        diff    = Math.abs(clickedValue-value)
        if (diff < mindiff) or (mindiff is undefined)
          mindiff       = diff
          closestHandle = handle

      closestHandle.setValue snappedValue

  viewAppended:->
    @setWidth @getOption "width"
    @createHandles()
    @setLimits()
    @drawBar()   if @getOption('drawBar')
    @addLabels() if @getOption('showLabels')
    @attachEvents()

class KDSliderBarHandleView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->
    options.tagName   = "a"
    options.cssClass  = "handle"
    data.value       ?= 0
    options.draggable =
      axis            : "x"

    super options, data

  attachEvents:->
    {maxValue, minValue, width} = @parent.getOptions()
    {value}                     = @getData()

    @on "DragStarted", ->
      value = @getData().value
    @on "DragInAction", ->
      relPos       = @dragState.position.relative.x
      valueChange  = ((maxValue-minValue)*relPos)/width
      @setValue value+valueChange
    @on "DragFinished", ->
      @snap() if @parent.getOption "snap"

  getPosition:->
    {maxValue, minValue} = @parent.getOptions()
    {value}              = @getData()
    sliderWidth          = @parent.getWidth()

    percentage = ((value-minValue)*100)/(maxValue-minValue)
    position   = (sliderWidth/100)*percentage

    return "#{position}px"

  setValue:(value)->
    {leftLimit, rightLimit} = @getData()

    if !(value<leftLimit) and !(value>rightLimit)
      @data.value = value
    
    else if value > rightLimit
      @data.value = rightLimit

    else if value < leftLimit
      @data.value = leftLimit

    @setX "#{@getPosition()}"
    @parent.drawBar() if @parent.getOption('drawBar')
    @parent.setLimits()
    @emit "ValueChange"
      
  getSnappedValue:(value)->
    {interval}  = @parent.getOptions()
    {value}     = value or @getData()
    
    if interval isnt no
      mod = value%interval
      mid = interval/2

      return value = switch
        when mod <= mid then value-mod
        when mod >  mid then value+(interval-mod)
        else value

  snap:->
    {interval}  = @parent.getOptions()
    value       = @getSnappedValue()

    if interval isnt no and @parent.getOption "snap"
      @setValue value
      @setX "#{@getPosition()}"
      @parent.drawBar() if @parent.getOption('drawBar')

  viewAppended:->
    @setX "#{@getPosition()}"
    @attachEvents()
    @snap() if @parent.getOption "snap"
    