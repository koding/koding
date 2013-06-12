class KDNotificationView extends KDView
  constructor:(options)->
    super options
    options = @notificationSetDefaults options

    @notificationSetType        options.type
    @notificationSetTitle       options.title         if options.title?
    @notificationSetContent     options.content       if options.content?
    @notificationSetTimer       options.duration      if options.duration?
    @notificationSetOverlay     options.overlay       if options.overlay?
    @notificationSetFollowUps   options.followUps     if options.followUps?

    @notificationShowTimer() if options.showTimer? and options.showTimer
    @notificationSetCloseHandle options.closeManually
    @notificationDisplay()

    @setLoader() if options.loader

  # OVERRIDE KDView
  setDomElement:(cssClass = '')->
    @domElement = $ "<div class='kdnotification #{cssClass}'>
        <a class='kdnotification-close hidden'></a>
        <div class='kdnotification-timer hidden'></div>
        <div class='kdnotification-title'></div>
        <div class='kdnotification-content hidden'></div>
      </div>"

  destroy:()->
    @notificationCloseHandle.unbind ".notification"
    @notificationOverlay.remove() if @notificationOverlay?
    super()
    @notificationStopTimer()
    @notificationRepositionOtherNotifications()

  viewAppended:()-> @notificationSetPositions()

  # OWN METHODS
  notificationSetDefaults:(options)->
    options.duration      ?= 1500
    if options.duration > 2999 or options.duration is 0
      options.closeManually ?= yes
    options.destroyOnClick?= yes
    return options

  notificationSetTitle:(title)->
    unless title instanceof KDView
      @$().find(".kdnotification-title").html title
    else
      @notificationTitle.destroy() if @notificationTitle and \
                                      @notificationTitle instanceof KDView
      @addSubView title, ".kdnotification-title"
    @notificationTitle = title

  notificationSetType:(type = "main")->
    @notificationType = type

  notificationSetPositions:()->
    @setClass @notificationType
    sameTypeNotifications = $("body").find ".kdnotification.#{@notificationType}"

    if @getOptions().container
      winHeight = @getOptions().container.getHeight()
      winWidth  = @getOptions().container.getWidth()
    else
      {winWidth, winHeight} = @getSingleton('windowController')

    switch @notificationType
      when "tray"
        bottomMargin = 8
        for notification,i in sameTypeNotifications
          bottomMargin += $(notification).outerHeight(no) + 8 if i isnt 0
        styles =
          bottom: bottomMargin
          right : 8
      when "growl"
        topMargin = 8
        for notification,i in sameTypeNotifications
          topMargin += $(notification).outerHeight(no) + 8 if i isnt 0
        styles =
          top   : topMargin
          right : 8
      when "mini"
        styles =
          top   : 0
          left  : winWidth/2 - @getDomElement().width()/2
      when "sticky"
        styles =
          top   : 0
          left  : winWidth/2 - @getDomElement().width()/2
      else
        styles =
          top   : winHeight/2 - @getDomElement().height()/2
          left  : winWidth/2 - @getDomElement().width()/2

    @getDomElement().css styles

  notificationRepositionOtherNotifications:()->

    sameTypeNotifications = $("body").find ".kdnotification.#{@notificationType}"
    heights = ($(elm).outerHeight(no) for elm,i in sameTypeNotifications)

    for elm,i in sameTypeNotifications
      switch @notificationType
        when "tray", "growl"
          newValue = 0
          position = if @notificationType is "tray" then "bottom" else "top"
          for h,j in heights[0..i]
            if j isnt 0 then newValue += h else newValue = 8
          options = {}
          options[position] = newValue + i*8
          $(elm).css options

  notificationSetCloseHandle:(closeManually = no)->
    @notificationCloseHandle = @getDomElement().find ".kdnotification-close"
    if closeManually
      @notificationCloseHandle.removeClass "hidden"

    @notificationCloseHandle.bind "click.notification",(e)=> @destroy()
    $(window).bind "keydown.notification",(e)=> @destroy() if e.which is 27

  notificationSetTimer:(duration)->
    return if duration is 0
    @notificationTimerDiv = @getDomElement().find ".kdnotification-timer"
    @notificationTimerDiv.text Math.floor duration/1000

    @notificationTimeout = setTimeout ()=>
      @getDomElement().fadeOut 200,()=>
        @destroy()
    ,duration

    @notificationInterval = setInterval ()=>
      next = parseInt(@notificationTimerDiv.text(),10) - 1
      @notificationTimerDiv.text next
    ,1000

  notificationSetFollowUps: (followUps)->
    unless Array.isArray followUps then followUps = [followUps]
    followUps.forEach (followUp)=>
      followUp.duration  ?= 10000
      @utils.wait followUp.duration, =>
        @notificationSetTitle   followUp.title    if followUp.title
        @notificationSetContent followUp.content  if followUp.content
        @notificationSetPositions()

  notificationShowTimer:()->
    @notificationTimerDiv.removeClass "hidden"
    @getDomElement().bind "mouseenter",()=>
      @notificationStopTimer()
    @getDomElement().bind "mouseleave",()=>
      newDuration = parseInt(@notificationTimerDiv.text(),10)*1000
      @notificationSetTimer newDuration

  notificationStopTimer:()->
    clearTimeout @notificationTimeout
    clearInterval @notificationInterval

  notificationSetOverlay:(options)->

    options.transparent ?= yes

    @notificationOverlay = $ "<div/>",
      class : "kdoverlay transparent"
    @notificationOverlay.hide()
    @notificationOverlay.removeClass "transparent"  if options.transparent is no
    @notificationOverlay.appendTo "body"
    @notificationOverlay.fadeIn 200
    @notificationOverlay.bind "click",()=>
      @destroy()  if @getOptions().destroyOnClick
  notificationGetOverlay:()-> @notificationOverlay

  setLoader:->
    @setClass "w-loader"
    {loader} = @getOptions()
    
    switch @notificationType
      when "tray"
        loaderSize = 25
      when "growl"
        loaderSize = 30
      when "mini"
        loaderSize = 18
      when "sticky"
        loaderSize = 25
      else
        loaderSize = 30

    loader.diameter or= loaderSize

    @loader = new KDLoaderView
      size          :
        width       : loader.diameter  ? loaderSize
      loaderOptions :
        color       : loader.color    or "#ffffff"
        shape       : loader.shape    or "spiral"
        diameter    : loader.diameter
        density     : loader.density   ? 30
        range       : loader.range     ? 0.4
        speed       : loader.speed     ? 1.5
        FPS         : loader.FPS       ? 24

    @addSubView @loader, null, yes
    @$().css
      paddingLeft : loader.diameter*2
    @loader.$().css
      position    : "absolute"
      left        : loader.left or Math.floor loader.diameter / 2
      top         : loader.top  or "50%"
      marginTop   : -(loader.diameter/2)
    @loader.show()

  showLoader:->
    @setClass "loading"
    @loader.show()

  hideLoader:->
    @unsetClass "loading"
    @loader?.hide()

  notificationSetContent:(content)->
    @notificationContent = content
    @getDomElement().find(".kdnotification-content").removeClass("hidden").html content

  notificationDisplay:()->
    if @getOptions().container
      @getOptions().container.addSubView @
    else
      KDView.appendToDOMBody @
