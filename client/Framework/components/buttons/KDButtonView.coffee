class KDButtonView extends KDView

  constructor:(options = {},data)->

    options.callback  or= noop          # a Function
    options.title     or= ""            # a String
    # options.style     or= "clean-gray"  # a String of one of button styles ==> DEPRECATE THIS
    options.type      or= "button"      # a String of submit, reset, button
    options.cssClass  or= options.style or= "clean-gray"            # a String
    options.icon      or= no            # a Boolean value
    options.iconOnly  or= no            # a Boolean value
    options.iconClass or= ""            # a String
    options.disabled  or= no            # a Boolean value
    options.hint      or= null          # a String of HTML ---> not yet implemented
    options.loader    or= no

    super options,data

    @setClass options.style

    @setCallback options.callback
    @setTitle options.title
    @setIconClass options.iconClass if options.iconClass
    @showIcon()                     if options.icon
    @setIconOnly options.iconOnly   if options.iconOnly
    @disable()                      if options.disabled

    if options.loader
      @on "viewAppended", @setLoader.bind @


  setDomElement:(cssClass)->
    @domElement = $ """
      <button type='#{@getOptions().type}' class='kdbutton #{cssClass}' id='#{@getId()}'>
        <span class='icon hidden'></span>
        <span class='button-title'>Title</span>
      </button>
      """

  setTitle:(title)->
    @$('.button-title').html title

  getTitle:()-> @buttonTitle

  setCallback:(callback)->
    @buttonCallback = callback

  getCallback:()-> @buttonCallback

  showIcon:()->
    @setClass "with-icon"
    @$('span.icon').removeClass 'hidden'


  setIconClass:(iconClass)->
    @$('.icon').attr 'class','icon'
    @$('.icon').addClass iconClass
    # @setClass iconClass

  setIconOnly:()->
    @unsetClass "with-icon"
    @$().addClass('icon-only')
    $icon = @$('span.icon')
    @$().html $icon

  setLoader:->
    @setClass "w-loader"
    {loader} = @getOptions()
    loaderSize = @getHeight()
    @loader = new KDLoaderView
      size          :
        width       : loader.diameter || loaderSize
      loaderOptions :
        color       : loader.color    || "#222222"
        shape       : loader.shape    || "spiral"
        diameter    : loader.diameter || loaderSize
        density     : loader.density  || 30
        range       : loader.range    || 0.4
        speed       : loader.speed    || 1.5
        FPS         : loader.FPS      || 24

    @addSubView @loader, null, yes
    @loader.$().css
      position    : "absolute"
      left        : loader.left or "50%"
      top         : loader.top or "50%"
      marginTop   : -(loader.diameter/2)
      marginLeft  : -(loader.diameter/2)
    @loader.hide()

  showLoader:->
    @setClass "loading"
    @loader.show()

  hideLoader:->
    @unsetClass "loading"
    @loader.hide()

  disable:-> @$().attr "disabled",yes

  enable:-> @$().attr "disabled",no

  focus:-> @$().trigger "focus"

  click:(event)->
    if @loader and @loader.active
      event.stopPropagation()
      event.preventDefault()
      return no
    if @loader and not @loader.active
      @showLoader()

    {type} = @getOptions()
    if type is "button"
      event.stopPropagation()
      event.preventDefault()

    @getCallback().call @,event
    no

  triggerClick:()-> @doOnSubmit()

class KDToggleButton extends KDButtonView

  constructor:(options = {},data)->

    options = $.extend
      dataPath     : null          # a JsPath String
      defaultState : null          # a String
      states       : []            # an Array of Objects in form of stateName : callback key/value pairs
    ,options

    super options,data

    @setState options.defaultState

  getStateIndex:(name)->

    {states} = @getOptions()
    unless name
      return 0
    else
      for state,index in states
        if name is state
          return index

  decorateState:(name)-> @setTitle @state

  getState:-> @state

  setState:(name)->

    {states} = @getOptions()
    @stateIndex = index = @getStateIndex name
    @state      = states[index]
    @decorateState name

    @setCallback states[index + 1].bind @, @toggleState.bind @

  toggleState:(err)->

    {states} = @getOptions()
    nextState = states[@stateIndex + 2] or states[0]
    unless err
      @setState nextState
    else
      warn err.msg or "there was an error, couldn't switch to #{nextState} state!"
