class KDModalView extends KDView
  constructor:(options,data)->
    options = $.extend
      overlay        : no            # a Boolean
      overlayClick   : yes           # a Boolean
      height         : "auto"        # a Number for pixel value or a String e.g. "100px" or "20%" or "auto"
      width          : 400           # a Number for pixel value or a String e.g. "100px" or "20%"
      position       : {}            # an Object holding top and left values
      title          : null          # a String of text or HTML
      content        : null          # a String of text or HTML
      cssClass       : ""            # a String
      buttons        : null          # an Object of button options
      fx             : no            # a Boolean
      view           : null          # a KDView instance
      draggable      : no
      # TO BE IMPLEMENTED
      resizable      : no            # a Boolean
    ,options


    super options,data

    @putOverlay options.overlay                   if options.overlay
    @setClass "fx"                                if options.fx
    @setTitle options.title                       if options.title
    @setContent options.content                   if options.content
    @addSubView options.view,".kdmodal-content"   if options.view

    KDView.appendToDOMBody @

    @setModalWidth options.width
    @setModalHeight options.height                if options.height

    if options.buttons
      @buttonHolder = new KDView {cssClass : "kdmodal-buttons clearfix"}
      @addSubView @buttonHolder, ".kdmodal-inner"
      @setButtons options.buttons

      modalButtonsInnerWidth = @$(".kdmodal-inner").width()
      @buttonHolder.setWidth modalButtonsInnerWidth

    # TODO: it is now displayed with setPositions method fix that and make .display work
    @display()
    @setPositions()
    
    # @getSingleton("windowController").setKeyView @ ---------> disabled because KDEnterinputView was not working in KDmodal
    $(window).on "keydown.modal",(e)=>
      @destroy() if e.which is 27

  setDomElement:(cssClass)->
    @domElement = $ "
    <div class='kdmodal #{cssClass}'>
      <div class='kdmodal-shadow'>
        <div class='kdmodal-inner'>
          <span class='close-icon closeModal'></span>
          <div class='kdmodal-title'></div>
          <div class='kdmodal-content'></div>
        </div>
      </div>
    </div>"

  setButtons:(buttonDataSet)->
    
    @buttons or= {}
    @setClass "with-buttons"
    for own buttonTitle, buttonOptions of buttonDataSet
      button = @createButton buttonTitle, buttonOptions
      @buttons[buttonTitle] = button
      if buttonOptions.focus
        focused = yes
        button.$().trigger "focus"

    unless focused
      @$("button").eq(0).trigger "focus"
      
  click:(e)->
    @destroy() if $(e.target).is(".closeModal")
    # @getSingleton("windowController").setKeyView @ ---------> disabled because KDEnterinputView was not working in KDmodal

  keyUp:(e)->
    @destroy() if e.which is 27
  
  setTitle:(title)-> 
    @getDomElement().find(".kdmodal-title").append("<span class='title'>#{title}</span>")
    @modalTitle = title

  setModalHeight:(value)->
    if value is "auto"
      @$().css "min-height","100px"
      @$().css "height","auto"
      @modalHeight = @getHeight()
    else 
      @$().height value
      @modalHeight = value

  setModalWidth:(value)-> 
    # if isNaN value
    @modalWidth = value
    @$().width value

  setPositions:()->
    @utils.nextTick =>
      {position} = @getOptions()
      newPosition = {}
  
      newPosition.top = if (position.top?) then position.top else ($(window).height()/2) - (@modalHeight/2)
      newPosition.left = if (position.left?) then position.left else ($(window).width()/2) - (@modalWidth/2)
      newPosition.left = $(window).width() - @modalWidth - position.right - 20 if position.right #20 is the padding FIX
      @$().css newPosition

  putOverlay:()->
    @$overlay = $ "<div/>"
      class : "kdoverlay"
    @$overlay.hide()
    @$overlay.appendTo "body"
    @$overlay.fadeIn 200
    if @getOptions().overlayClick
      @$overlay.bind "click",()=>
        @destroy()

  createButton:(title,buttonOptions)->
    
    buttonOptions.title = title
    @buttonHolder.addSubView button = new KDButtonView buttonOptions
      # title       : title
      # style       : buttonOptions.style     if buttonOptions.style?
      # callback    : buttonOptions.callback  if buttonOptions.callback?
    button.registerListener KDEventTypes:'KDModalShouldClose', listener:@, callback:->
      @propagateEvent KDEventType:'KDModalShouldClose'
    button

  setContent:(content)->
    @modalContent = content
    @getDomElement().find(".kdmodal-content").html content

  display:()->

    if @getOptions().fx
      @utils.nextTick =>
        @setClass "active"

  addInnerSubView:(view)->
    @addSubView view,".kdmodal-content"

  destroy:()->
    $(window).off "keydown.modal"
    uber = KDView::destroy.bind(@)

    if @options.fx
      @unsetClass "active"
      setTimeout uber,300
      @propagateEvent KDEventType : 'KDModalViewDestroyed'
    else
      @getDomElement().hide()
      uber()
      @propagateEvent KDEventType : 'KDModalViewDestroyed'