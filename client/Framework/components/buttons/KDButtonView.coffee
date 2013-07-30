class KDButtonView extends KDView

  constructor:(options = {}, data)->

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
    @showIcon()                     if options.icon or options.iconOnly
    @setIconOnly options.iconOnly   if options.iconOnly
    @disable()                      if options.disabled

    if options.focus
      @once "viewAppended", @bound "setFocus"

    if options.loader
      @once "viewAppended", @bound "setLoader"

  setFocus:-> @$().trigger 'focus'

  setDomElement:(cssClass)->
    {lazyDomId, tagName} = @getOptions()

    if lazyDomId
      el = document.getElementById lazyDomId
      for klass in "kdview #{cssClass}".split ' ' when klass.length
        el.classList.add klass

    unless el?
      warn "No lazy DOM Element found with given id #{lazyDomId}."  if lazyDomId
      el =
      """
      <button type='#{@getOptions().type}' class='kdbutton #{cssClass}' id='#{@getId()}'>
        <span class='icon hidden'></span>
        <span class='button-title'>Title</span>
      </button>
      """

    @domElement = $ el


  setTitle:(title)->
    @buttonTitle = title
    @$('.button-title').html title

  getTitle:-> @buttonTitle

  setCallback:(callback)->
    @buttonCallback = callback

  getCallback:-> @buttonCallback

  showIcon:->
    @setClass "with-icon"
    @$('span.icon').removeClass 'hidden'

  hideIcon:->
    @unsetClass "with-icon"
    @$('span.icon').addClass 'hidden'

  setIconClass:(iconClass)->
    @$('.icon').attr 'class','icon'
    @$('.icon').addClass iconClass
    # @setClass iconClass

  setIconOnly:->
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
        width       : loader.diameter  ? loaderSize
      loaderOptions :
        color       : loader.color    or "#222222"
        shape       : loader.shape    or "spiral"
        diameter    : loader.diameter  ? loaderSize
        density     : loader.density   ? 30
        range       : loader.range     ? 0.4
        speed       : loader.speed     ? 1.5
        FPS         : loader.FPS       ? 24

    @addSubView @loader, null, yes
    @loader.$().css
      position    : "absolute"
      left        : loader.left or "50%"
      top         : loader.top or "50%"
      marginTop   : -(loader.diameter/2)
      marginLeft  : -(loader.diameter/2)
    @loader.hide()

  showLoader:->
    {icon, iconOnly} = @getOptions()
    @setClass "loading"
    @loader.show()
    @hideIcon() if icon and not iconOnly

  hideLoader:->
    {icon, iconOnly} = @getOptions()
    @unsetClass "loading"
    @loader?.hide()
    @showIcon() if icon and not iconOnly

  disable:-> @$().attr "disabled", yes

  enable:-> @$().attr "disabled", no

  focus:-> @$().trigger "focus"
  
  blur:-> @$().trigger "blur"

  click:(event)->

    return @utils.stopDOMEvent()  if @loader?.active

    @showLoader()          if @loader and not @loader.active
    @utils.stopDOMEvent()  if @getOption('type') is "button"

    @getCallback().call @, event

    return no

  triggerClick:-> @doOnSubmit()
