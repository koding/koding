class KDSliderBarView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->
    options.cssClass      = KD.utils.curryCssClass "sliderbar-container", options.cssClass
    options.minValue      or= 0
    options.maxValue      or= 100
    options.step          or= 10
    options.handles
    
    super options, data

  createHandles:->
    @handles = []

    for k, v of @getOption('handles')
      handle   = new KDSliderBarHandleView
        name  : k
      , value : v.value
      @handles.push handle

    for i in @handles
      value     = i.getData().value
      maxValue  = @getOption('maxValue')
      pos       = (value/maxValue)*100

      i.$().css("left","#{value}%")
      @addSubView i

  getValues:->
    values = []
    for i in @handles
      values.push(i.getData().value)

    return values

  viewAppended:->
    @createHandles()
    log @getValues()

class KDSliderBarHandleView extends KDCustomHTMLView
  constructor:(options = {}, data = {})->
    options.cssClass      = "handle"
    options.name
    data.value           ?= 0

    super options, data

  initEvents:->
    handle          = @
    container       = @.parent
    containerBounds = container.getBounds()
    relPos          = 0

    handle.$().on "mousedown", ->
      container.$().on "mousemove",(event) ->
        relPos = ((event.pageX - containerBounds.x)/containerBounds.w)*100

        if !(relPos < 0) and !(relPos > 100)
          handle.$().css('left',relPos+'%')

    handle.$().on "mouseup",->
      container.$().off "mousemove"
      handle.data.value = relPos

    container.$().on "mouseleave",->
      container.$().off "mousemove"
      handle.data.value = relPos            
      
  viewAppended:->
    @initEvents()


