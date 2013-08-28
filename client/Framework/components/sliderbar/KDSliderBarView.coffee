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

    @handles            = []
    @labels             = []

    super options, data

  createHandles:->
    for k, v of @getData().handles
      @handles.push @addSubView handle = new KDSliderBarHandleView
          name : k
        , value: v.value

    sortRef = (a,b) ->
      return -1 if a.getData().value < b.getData().value
      return 1 if a.getData().value > b.getData().value
      return 0
    @handles.sort sortRef

  drawBar:->
    positions = []
    for i in @handles
      positions.push i.getPosition()

    len    = positions.length
    left   = (positions[0] if len>1) || 0
    right  = positions[len-1]
    diff   = right - left

    if !@bar
      @addSubView @bar = new KDCustomHTMLView
        cssClass : "bar"
    @bar.setWidth diff, "%"
    @bar.setX "#{left}%"

  addLabels:->
    maxValue = @getOption('maxValue')
    minValue = @getOption('minValue')
    interval = @getOption('interval')

    for v in [minValue..maxValue] by interval
      pos = ((v-minValue)*100)/(maxValue-minValue)

      @labels.push @addSubView label = new KDCustomHTMLView
        cssClass    : "sliderbar-label"
        partial     : "#{v}"

      label.setX "#{pos}%"

  getValues:(handleName)->
    if handleName?
      return @getHandle(handleName)?.getData().value

    else if @handles.length == 1
      return @handles[0].getData().value

    else
      values = []
      for i in @handles
        values.push i.getData().value
      return values

  getHandle:(name)->
    if name?
      for i in @handles
        return i if i.getOption('name') == name
      return console.error "Can't find a handle named #{name}"

  setLimits:->
    maxValue = @getOption('maxValue')
    minValue = @getOption('minValue')
    interval = @getOption("interval")

    if @handles.length is 1
      @handles[0].leftLimit   = @getOption('minValue')
      @handles[0].rightLimit  = @getOption('maxValue')
    else
      for h in @handles
        i = @handles.indexOf(h) 
        h.data.leftLimit  = @handles[i-1]?.getData().value + interval || minValue
        h.data.rightLimit = @handles[i+1]?.getData().value - interval || maxValue 

  viewAppended:->
    @createHandles()
    @setLimits()
    @drawBar()   if @getOption('drawBar')
    @addLabels() if @getOption('showLabels')

class KDSliderBarHandleView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->
    options.cssClass  = "handle"
    options.name
    data.value       ?= 0

    super options, data

  attachEvents:->
    maxValue         = @parent.getOption('maxValue')
    minValue         = @parent.getOption('minValue')
    windowController = KD.getSingleton "windowController"

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
    maxValue = @parent.getOption('maxValue')
    minValue = @parent.getOption('minValue')
    value    = @getData().value

    return ((value-minValue)*100)/(maxValue-minValue)

  setValue:(value)->
    leftLimit     = @getData().leftLimit
    rightLimit    = @getData().rightLimit

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
    interval = @parent.getOption('interval')
    value    = @getData().value
    
    if interval isnt no
      mod = value%interval
      mid = interval/2

      return value = switch
        when mod <= mid then value-mod
        when mod >  mid then value+(interval-mod)
        else value

  snap:->
    interval = @parent.getOption "interval"
    value    = @getSnappedValue()

    if interval isnt no and @parent.getOption "snap"
      @setValue value
      @setX "#{@getPosition()}%"
      @parent.drawBar()

  viewAppended:->
    @setX "#{@getPosition()}%"
    @attachEvents()
    @snap() if @parent.getOption "snap"