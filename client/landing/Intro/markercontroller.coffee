class MarkerController extends KDController

  constructor:->

    super

    @collection = {}

  create:(name = Date.now(), options = {})->

    options.name         = KD.utils.curry "m_", name
    options.offset      ?= {}
    options.offset.top  ?= 0
    options.offset.left ?= 0
    options.wait        ?= 0
    options.container  or= null         # [String window], [String selector] or [Object KDView]
    options.client     or= 'window'     # [String window], [String selector] or [Object KDView]

    if @collection[name]
      warn 'marker exists', name
    else
      @collection[name] = new Marker options

    return @collection[name]

  group:(groupName = Date.now(), markers...)->

    groupName = "g_#{groupName}"
    @collection[groupName] = markers

    return @groups[groupName]

  hide:(name)->

    # hide group if it is a group name
    if markers = @collection["g_#{name}"]

      marker.hide() for marker in markers

      return markers

    # hide marker if it is a marker name
    if marker = @collection["m_#{name}"]

      marker.hide()

      return marker



class Marker extends KDCustomHTMLView

  constructor:(options = {})->

    options.tagName  = 'span'
    options.partial  = '<i></i>'
    options.cssClass = KD.utils.curry 'intro-marker hidden', options.cssClass

    super options

    @bindTransitionEnd()
    @listenWindowResize()

    @once 'viewAppended', =>
      @show()
      @setPosition @getClientPosition()

    KD.utils.wait options.wait, => @append()

  _windowDidResize:->
    @setPosition @getClientPosition()

  append:->

    {container} = @getOptions()

    if container instanceof KDView
      container.addSubView this
    else if 'string' is typeof container
      switch container
        when 'window' then @appendToDOMBody()
        else
          $(container).append @$()
          @utils.defer => @emit "viewAppended"
    else
      @appendToDOMBody()

  getClientPosition:->

    {client} = @getOptions()

    top  = 0
    left = 0

    if client instanceof KDView
      top  = client.getY()
      left = client.getX()
    else if 'string' is typeof client and client isnt 'window'
      {top, left} = $(client).offset()

    return {top, left}

  setPosition:({top, left})->

    {offset} = @getOptions()
    # probably we need to take container into account as well here
    # this is good for now. - SY
    @setY top  + offset.top
    @setX left + offset.left

  click:->

    Marker.message?.destroy()

    Marker.message = new MarkerMessage
      position     :
        top        : @getY() + 100
        left       : @getX() + 50

  show:->

    super

    KD.utils.defer => @setClass 'in'

  hide:->

    @once 'transitionend', => super

    @unsetClass 'in'

class MarkerMessage extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.partial or= 'This is a marker message!'