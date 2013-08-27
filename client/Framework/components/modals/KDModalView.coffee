class KDModalView extends KDView

  constructor:(options = {}, data)->
    options.overlay       ?= no            # a Boolean
    options.overlayClick  ?= yes           # a Boolean
    options.height       or= "auto"        # a Number for pixel value or a String e.g. "100px" or "20%" or "auto"
    options.width         ?= 400           # a Number for pixel value or a String e.g. "100px" or "20%"
    options.position     or= {}            # an Object holding top and left values
    options.title        or= null          # a String of text or HTML
    options.content      or= null          # a String of text or HTML
    options.cssClass     or= ""            # a String
    options.buttons      or= null          # an Object of button options
    options.fx            ?= no            # a Boolean
    options.view         or= null          # a KDView instance
    options.draggable    or= handle : ".kdmodal-title"
    # TO BE IMPLEMENTED
    options.resizable     ?= no            # a Boolean

    options.helpContent  or= null
    options.helpTitle    or= "Need help?"

    super options, data

    @setClass "initial"
    @putOverlay options.overlay                   if options.overlay
    @setClass "fx"                                if options.fx
    @setTitle options.title                       if options.title
    @setContent options.content                   if options.content
    @addSubView options.view                      if options.view

    @on 'ModalCancelled', options.cancel          if options.cancel

    @on "viewAppended", =>
      @utils.wait 500, => @unsetClass "initial"

    KDView.appendToDOMBody @

    @setModalWidth  options.width
    @setModalHeight options.height                if options.height

    if options.buttons
      @buttonHolder = new KDView {cssClass : "kdmodal-buttons clearfix"}
      @addSubView @buttonHolder, ".kdmodal-inner"
      @setButtons options.buttons

      modalButtonsInnerWidth = @$(".kdmodal-inner").width()
      @buttonHolder.setWidth modalButtonsInnerWidth

    # TODO: it is now displayed with setPositions method fix that and make .display work
    @display()
    @_windowDidResize()

    # KD.getSingleton("windowController").setKeyView @ ---------> disabled because KDEnterinputView was not working in KDmodal
    $(window).one "keydown.modal",(e)=>
      @cancel() if e.which is 27

    @on "childAppended", @setPositions.bind @

    @listenWindowResize()

  setDomElement:(cssClass)->
    {helpContent, helpTitle} = @getOptions()

    if helpContent
      helpButton = "<span class='showHelp'>#{helpTitle}</span>"
    else
      helpButton = ""

    @domElement = $ """
      <div class='kdmodal #{cssClass}'>
        <div class='kdmodal-shadow'>
          <div class='kdmodal-inner'>
            #{helpButton}
            <span class='close-icon closeModal' title='Close [ESC]'></span>
            <div class='kdmodal-title hidden'></div>
            <div class='kdmodal-content'></div>
          </div>
        </div>
      </div>
    """

  addSubView:(view, selector = ".kdmodal-content")->
    selector = null if @$(selector).length is 0
    super view, selector

  setButtons:(buttonDataSet, destroyExists = no)->
    @buttons or= {}
    @setClass "with-buttons"
    defaultFocusTitle = null
    @destroyButtons()  if destroyExists
    for own buttonTitle, buttonOptions of buttonDataSet
      defaultFocusTitle ?= buttonTitle
      button = @createButton buttonOptions.title or buttonTitle, buttonOptions
      @buttons[buttonTitle] = button
      focused = yes  if buttonOptions.focus

    @buttons[defaultFocusTitle].setFocus()  unless focused

  destroyButtons:->
    button.destroy()  for own _, button of @buttons

  click:(e)->
    @destroy() if $(e.target).is(".closeModal")
    if $(e.target).is(".showHelp")
      {helpContent} = @getOptions()
      if helpContent
        helpContent = KD.utils.applyMarkdown helpContent
        new KDModalView
          # title   : "Help"
          cssClass : "help-dialog"
          overlay  : yes
          content  : "<div class='modalformline'><p>#{helpContent}</p></div>"

    # KD.getSingleton("windowController").setKeyView @ ---------> disabled because KDEnterinputView was not working in KDmodal

  # keyUp:(e)->
  #   @cancel() if e.which is 27

  setTitle:(title)->
    @$().find(".kdmodal-title").removeClass('hidden').html("<span class='title'>#{title}</span>")
    @modalTitle = title

  setModalHeight:(value)->
    if value is "auto"
      # @$().css "min-height","100px"
      @$().css "height","auto"
      @modalHeight = @getHeight()
    else
      @$().height value
      @modalHeight = value

  setModalWidth:(value)->
    # if isNaN value
    @modalWidth = value
    @$().width value

  setPositions:->
    @utils.defer =>
      {top, right, bottom, left} = @getOptions().position
      newRules = {}
      height = $(window).height()
      width  = $(window).width()
      newRules.top  = if top?  then top  else height/2 - @getHeight()/2
      newRules.left = if left? then left else width/2  - @modalWidth/2
      newRules.left = width - @modalWidth - right - 20 if right #20 is the padding FIX
      newRules.opacity = 1
      @$().css newRules

  _windowDidResize:->
    @setPositions()
    {winHeight} = KD.getSingleton('windowController')
    @$('.kdmodal-content').css
      maxHeight: winHeight - 120
      overflow : "auto"
    @setY (winHeight - @getHeight()) / 2 unless @getOptions().position.top

  putOverlay:->
    @$overlay = $ "<div/>",
      class : "kdoverlay"
    @$overlay.hide()
    @$overlay.appendTo "body"
    @$overlay.fadeIn 200
    if @getOptions().overlayClick
      @$overlay.bind "click",()=>
        @destroy()

  createButton:(title, buttonOptions)->
    buttonOptions.title    = title
    buttonOptions.delegate = @
    itemClass = buttonOptions.itemClass
    delete buttonOptions.itemClass
    @buttonHolder.addSubView button = new (itemClass or KDButtonView) buttonOptions
    # @buttonHolder.addSubView button = new KDButtonView buttonOptions
      # title       : title
      # style       : buttonOptions.style     if buttonOptions.style?
      # callback    : buttonOptions.callback  if buttonOptions.callback?
    button.on 'KDModalShouldClose', => @emit 'KDModalShouldClose'
    button

  setContent:(content)->
    @modalContent = content
    @getDomElement().find(".kdmodal-content").html content

  display:->
    if @getOptions().fx
      @utils.defer =>
        @setClass "active"

  cancel:->
    @emit 'ModalCancelled'
    @destroy()

  destroy:->
    $(window).off "keydown.modal"
    uber = KDView::destroy.bind @

    if @options.fx
      @unsetClass "active"
      setTimeout uber, 300
    else
      @getDomElement().hide()
      uber()

    @emit 'KDModalViewDestroyed', @

  ### STACK HELPERS ###

  @createStack: (options)->
    @stack or= new KDModalViewStack options

  @addToStack: (modal)->
    @stack.addModal modal

  @destroyStack: (force=no)->
    @stack.destroy()
    delete @stack