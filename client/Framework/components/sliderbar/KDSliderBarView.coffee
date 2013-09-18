# example = new KDSliderBarView
#   cssClass   : 'my-cute-slider'
#   minValue   : 0
#   maxValue   : 200
#   interval   : 10
#   width      : 500
#   snap       : yes
#   snapOnDrag : no
#   drawBar    : yes
#   showLabels : yes or [0, 25, 50, 75, 100] 
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
    @setClass "labeled"

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

  _createLabel : (value) =>
    {maxValue, minValue, interval, showLabels} = @getOptions()

    pos = ((value - minValue) * 100) / (maxValue - minValue)
    @labels.push @addSubView label = new KDCustomHTMLView
      cssClass    : "sliderbar-label"
      partial     : "#{value}"
    label.setX "#{pos}%"

  addLabels:->
    {maxValue, minValue, interval, showLabels} = @getOptions()

    if Array.isArray showLabels
    then @_createLabel value for value in showLabels
    else @_createLabel value for value in [minValue..maxValue] by interval

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