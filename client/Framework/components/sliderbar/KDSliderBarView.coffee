class KDSliderBarView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->

    options.cssClass    = KD.utils.curryCssClass "sliderbar-container", options.cssClass
    options.minValue   ?= 0
    options.maxValue   ?= 100
    options.interval   ?= no
    options.drawBar    ?= yes
    options.showLabels ?= yes
    options.snap       ?= yes
    data.handles

    super options, data

    @handles            = []
    @labels             = []

  createHandles:->
    for name, {value} of @getData().handles
      @handles.push @addSubView handle = new KDSliderBarHandleView {name}, {value}

    sortRef = (a,b) ->
      return -1 if a.getData().value < b.getData().value
      return 1 if a.getData().value > b.getData().value
      return 0
    @handles.sort sortRef

  drawBar:->
    positions = []
    for handle in @handles
      positions.push handle.getPosition()

    len    = positions.length
    left   = (positions.first if len>1) or 0
    right  = positions.last
    diff   = right - left

    unless @bar
      @addSubView @bar = new KDCustomHTMLView
        cssClass : "bar"
    @bar.setWidth diff, "%"
    @bar.setX "#{left}%"

  addLabels:->
    {maxValue, minValue, interval} = @getOptions()

    for value in [minValue..maxValue] by interval
      pos = ((value-minValue)*100)/(maxValue-minValue)

      @labels.push @addSubView label = new KDCustomHTMLView
        cssClass    : "sliderbar-label"
        partial     : "#{value}"

      label.setX "#{pos}%"

  getValues:(handleName)->
    if handleName?
      return @getHandle(handleName)?.getData().value

    else if @handles.length is 1
      return @handles.first.getData().value

    else
      values = []
      for handle in @handles
        values.push handle.getData().value
      return values

  getHandle:(name)->
    if name?
      for handle in @handles
        return handle if handle.getOption('name') is name
      return console.error "Can't find a handle named #{name}"

  setLimits:->
    {maxValue, minValue, interval} = @getOptions()

    if @handles.length is 1
      @handles.first.leftLimit     = minValue
      @handles.first.rightLimit    = maxValue
    else
      for handle in @handles
        i    = @handles.indexOf(handle)
        data = handle.data

        data.leftLimit  = @handles[i-1]?.getData().value + interval or minValue
        data.rightLimit = @handles[i+1]?.getData().value - interval or maxValue 

  viewAppended:->
    @createHandles()
    @setLimits()
    @drawBar()   if @getOption('drawBar')
    @addLabels() if @getOption('showLabels')
    window.asd = @

class KDSliderBarHandleView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->
    options.cssClass  = "handle"
    options.name
    data.value       ?= 0

    super options, data

  attachEvents:->
    {maxValue, minValue} = @parent.getOptions()
    windowController     = KD.getSingleton "windowController"

    @on "mousedown", ->
      @parent.bindEvent "mousemove"
      windowController.setDragInAction true

      @parent.on "mousemove", (event) =>
        relPos  = (((event.pageX - @parent.getX())/@parent.getWidth())*100)
        @setValue ((relPos*(maxValue - minValue))/100)+minValue

      @on "mouseup", dragEnded
      @parent.on "mouseleave", dragEnded

    dragEnded = ->
      @parent.off "mousemove"
      windowController.setDragInAction false
      @snap() if @parent.getOption "snap"

  getPosition:->
    {maxValue, minValue} = @parent.getOptions()
    {value}              = @getData()

    return ((value-minValue)*100)/(maxValue-minValue)

  setValue:(value)->
    {leftLimit, rightLimit} = @getData()

    if !(value<leftLimit) and !(value>rightLimit)
      @data.value = value
    
    else if value > rightLimit
      @data.value = rightLimit

    else if value < leftLimit
      @data.value = leftLimit

    @parent.drawBar()
    @parent.setLimits()
    @setX "#{@getPosition()}%"
      
  getSnappedValue:->
    {interval}  = @parent.getOptions()
    {value}     = @getData()
    
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
      @setX "#{@getPosition()}%"
      @parent.drawBar()

  viewAppended:->
    @setX "#{@getPosition()}%"
    @attachEvents()
    @snap() if @parent.getOption "snap"