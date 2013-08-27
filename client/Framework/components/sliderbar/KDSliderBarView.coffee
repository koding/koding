class KDSliderBarView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->
    options.cssClass        = KD.utils.curryCssClass "sliderbar-container", options.cssClass
    options.minValue      or= 0
    options.maxValue      or= 100
    options.interval          or= no
    options.drawBar        ?= yes
    data.handles

    @handles                = []

    super options, data

  createHandles:->
    maxValue = @getOption('maxValue')
    minValue = @getOption('minValue')

    for k, v of @getData().handles
      handle = new KDSliderBarHandleView
        name : k
      , value: v.value

      @addSubView handle
      @handles.push handle

  drawBar:->
    positions = []

    for i in @handles
      positions.push i.getPosition()

    sortRef = (a,b) -> return a-b

    positions.sort(sortRef)
    len    = positions.length

    right  = positions[len-1]

    if len>1
      left = positions[0]
    else
      left = 0

    diff = right - left

    if !@bar?
      @bar = new KDCustomHTMLView
        cssClass : "bar"
      @addSubView @bar
    
    @bar.setWidth diff, "%"
    @bar.setX "#{left}%"

  getValues:->
    values = []
    for i in @handles
      values.push i.getData().value
    
    return values

  viewAppended:->
    @createHandles()
    @drawBar()
    window.asd = @

class KDSliderBarHandleView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->
    options.cssClass      = "handle"
    options.name
    data.value           ?= 0

    super options, data

  attachEvents:->
    maxValue = @parent.getOption('maxValue')
    minValue = @parent.getOption('minValue')

    @on "mousedown",(e) ->
      @parent.bindEvent "mousemove"
      @parent.on "mousemove", (event) =>

        relPos  = (((event.pageX - @parent.getX())/@parent.getWidth())*100)
        @setValue ((relPos*(maxValue - minValue))/100)+minValue

        @setX "#{@getPosition()}%"

      @on "mouseup", =>
        @parent.off "mousemove"
        @snap()

      @parent.on "mouseleave", =>
        @parent.off "mousemove"
        @snap()


  getPosition:->
    maxValue = @parent.getOption('maxValue')
    minValue = @parent.getOption('minValue')
    value    = @getData().value

    position = ((value-minValue)*100)/(maxValue-minValue)
    return position

  setValue:(value)->
    if !(value<@parent.getOption('minValue')) and !(value>@parent.getOption('maxValue'))
      @data.value = value
    else if value > 100
      @data.value = 100
    else if value < 0
      @data.value = 0 

    @parent.drawBar()

  snap:->
    interval = @parent.getOption('interval')
    value = @getData().value
    
    if interval isnt no
      mod = value%interval
      mid = interval/2

      value = switch
        when mod <= mid then value-mod
        when mod >  mid then value+(interval-mod)
        else value

      @setValue value
      @setX "#{@getPosition()}%"
      @parent.drawBar()

  viewAppended:->
    @setX "#{@getPosition()}%"
    @attachEvents()
    













