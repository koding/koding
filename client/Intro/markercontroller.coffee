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


  reset:->

    for own name, marker of @collection when name.slice(2) is 'm_'

      marker._windowDidResize()


  group:(groupName = Date.now(), markers...)->

    groupName = "g_#{groupName}"
    @collection[groupName] = markers

    return markers


  hide:(name)->

    # hide group if it is a group name
    if markers = @collection["g_#{name}"]
      marker.hide() for marker in markers

      return markers

    # hide marker if it is a marker name
    if marker = @collection["m_#{name}"]
      marker.hide()

      return marker


  show:(name)->

    # show group if it is a group name
    if markers = @collection["g_#{name}"]
      marker.show() for marker in markers

      return markers

    # show marker if it is a marker name
    if marker = @collection["m_#{name}"]
      marker.show()

      return marker



class Marker extends KDCustomHTMLView

  constructor:(options = {})->

    options.tagName  = 'span'
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

  append:(view = this)->

    {container} = @getOptions()

    if container instanceof KDView
      container.addSubView view
    else if 'string' is typeof container
      switch container
        when 'window' then view.appendToDOMBody()
        else
          $(container).append view.$()
          KD.utils.defer -> view.emit "viewAppended"
    else
      view.appendToDOMBody()

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

  click: do ->

    message    = null

    _.throttle ->
      # close the same message and stop
      # if marker clicked repeatedly
      if message?.getDelegate() is this
        message.destroy()
        message = null
        return

      message?.destroy()

      message = new MarkerMessage
        partial  : @getOptions().message
        delegate : this
        position :
          top    : @getY()
          left   : @getX()


      message.once 'viewAppended', =>
        message.setX @getX() - message.getWidth() / 2 + @getWidth() / 2
        message.setY @getY() - message.getHeight() - 30

      message.once 'transitionend', ->
        # it may be double clicked and destroyed even before
        # transition ends, so we're being cautious here - SY
        message?.setPartial '<cite></cite>'
        KD.utils.defer ->
          message?.$('cite').addClass 'in'


      @append message

    , 300


  show:->

    super

    KD.utils.defer => @setClass 'in'

  hide:->

    @once 'transitionend', => super

    @unsetClass 'in'

class MarkerMessage extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.cssClass  = KD.utils.curry 'marker-message', options.cssClass
    options.partial or= 'This is a marker message!'

    super

    KD.utils.defer => @setClass 'in'

    @bindTransitionEnd()

    KD.getSingleton('windowController').addLayer this
    @once 'ReceivedClickElsewhere', @bound 'destroy'

  destroy:->

    return if @isBeingDestroyed

    @isBeingDestroyed = yes
    @once 'transitionend', =>
      KD.utils.wait 300, =>
        @destroy()
        @isBeingDestroyed = no
      @unsetClass 'in'

    @$('cite').removeClass 'in'



