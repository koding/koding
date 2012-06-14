class KDButtonView extends KDView

  @styles = [
    "minimal","clean-gray","cupid-green","cupid-blue","blue-pill"
    "dribbble","slick-black","thoughtbot","blue-candy","purple-candy"
    "shiny-blue","small-blue","skip","clean-red","small-gray","transparent"
  ]

  constructor:(options = {},data)->
    options = $.extend
      callback     : noop          # a Function
      title        : ""            # a String
      style        : "clean-gray"  # a String of one of button styles
      type         : "button"      # a String of submit, reset, button
      cssClass     : ""            # a String
      icon         : no            # a Boolean value
      iconOnly     : no            # a Boolean value
      iconClass    : ""            # a String  
      disabled     : no            # a Boolean value
      hint         : null          # a String of HTML ---> not yet implemented
      loader       : no
      # name         : ""
      # value        : ""
    ,options
    
    super options,data

    @setCallback options.callback
    @setTitle options.title
    @setButtonStyle options.style
    # @setName options.name           if options.name
    # @setValue options.value         if options.value
    @setIconClass options.iconClass if options.iconClass
    @unhideIcon()                   if options.icon
    @setIconOnly options.iconOnly   if options.iconOnly
    @disable()                      if options.disabled
    
    if options.loader
      @listenTo 
        KDEventTypes       : "viewAppended"
        listenedToInstance : @
        callback           : ->
          @setLoader()
    

  setDomElement:()->
    @domElement = $ """
      <button type='#{@getOptions().type}' class='kdbutton clean-gray' id='#{@getId()}'>
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
  
  # setName:(name)->
  #   @$().attr {name}
  # 
  # setValue:(value)->
  #   @$().attr {value}
  
  unhideIcon:()->
    @setClass "with-icon"
    @$('span.icon').removeClass 'hidden'
  
  
  # refactor this
  # this seems unnecessary just use cssClass maybe
  setButtonStyle:(newStyle)->
    {styles} = @constructor
    for style in styles
      @getDomElement().removeClass style
    @getDomElement().addClass newStyle

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
    @loader.$().css position : "absolute", left : loader.left or 5, top : loader.top or 5
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
      dataPath : null          # a JsPath String
      states   : []            # an Array of Objects in form of stateName : callback key/value pairs
    ,options

    super options,data
    @setDefaultStates()
    @setState()
    
    @attachListener()
    
  attachListener:->

    {dataPath} = @getOptions()
    if dataPath
      @getData().on dataPath, =>
        @setState dataPath

  setDefaultStates:->

    {states} = @getOptions()
    if states.length < 3
      @options.states = ['default',-> warn "no state options passed" ]
    else
      return

  getStateIndex:(name)->

    {states} = @getOptions()
    unless name
      return 0
    else
      for state,index in states
        if name is state
          return index

  setState:(name)->

    {states} = @getOptions()
    @stateIndex = index = @getStateIndex name
    @state      = states[index]
    
    @setTitle @state
    @setCallback states[index + 1].bind @, @toggleState.bind @

  toggleState:(err)->

    {states} = @getOptions()
    nextState = states[@stateIndex + 2] or states[0]
    unless err
      @setState nextState
    else
      warn err.msg or "there was an error, couldn't switch to #{nextState} state!"













