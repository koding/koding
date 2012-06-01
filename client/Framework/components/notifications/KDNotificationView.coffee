class KDNotificationView extends KDView
  constructor:(options)->
    super options
    options = @notificationSetDefaults options

    @notificationSetType    options.type
    @notificationSetTitle   options.title     if options.title?
    @notificationSetContent options.content   if options.content?
    @notificationSetTimer   options.duration  if options.duration?
    @notificationSetOverlay options.overlay   if options.overlay? and options.overlay

    @notificationShowTimer() if options.showTimer? and options.showTimer
    @notificationSetCloseHandle options.closeManually
    @notificationDisplay()

  #OVERRIDE KDView
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
    
  #OWN METHODS
  notificationSetDefaults:(options)->
    options.duration      = options.duration ? 1500
    options.closeManually = yes if options.duration > 2999 or options.duration is 0
    options

  notificationSetTitle:(title)-> 
    @notificationTitle = title
    @getDomElement().find(".kdnotification-title").html title
  
  notificationSetType:(type = "main")->
    @notificationType = type
  
  notificationSetPositions:()->
    @setClass @notificationType
    sameTypeNotifications = @notificationGetSameTypeNotifications @notificationType
    
    if @getOptions().container
      winHeight = @getOptions().container.getHeight()
      winWidth  = @getOptions().container.getWidth()
    else
      {winWidth, winHeight} = @getSingleton('windowController')

    switch @notificationType
      when "tray"
        bottomMargin = 8
        for notification,i in sameTypeNotifications
          bottomMargin += $(notification).outerHeight() + 8 if i isnt 0
        styles =
          bottom: "#{bottomMargin}px"
          right : "8px"
      when "growl"
        topMargin = 8
        for notification,i in sameTypeNotifications
          topMargin += $(notification).outerHeight() + 8 if i isnt 0
        styles =
          top   : "#{topMargin}px"
          right : "8px"
      when "mini"
        styles =
          top   : 0
          left  : winWidth/2 - @getDomElement().width()/2
      else
        styles =
          top   : winHeight/2 - @getDomElement().height()/2
          left  : winWidth/2 - @getDomElement().width()/2

    @getDomElement().css styles
  
  notificationRepositionOtherNotifications:()->
    sameTypeNotifications = @notificationGetSameTypeNotifications @notificationType
    heights = []
    for notificationDiv,i in sameTypeNotifications
      heights.push $(notificationDiv).outerHeight()
    
    for notificationDiv,i in sameTypeNotifications
      switch @notificationType
        when "tray", "growl"
          newValue = 0
          position = if @notificationType is "tray" then "bottom" else "top"
          for h,j in heights[0..i]
            if j isnt 0 then newValue += h else newValue = 8
          options = {}
          options[position] = newValue + i*8
          $(notificationDiv).animate options

  notificationGetSameTypeNotifications:(type)-> $("body").find ".kdnotification.#{type}"

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

  notificationSetOverlay:()->
    @notificationOverlay = $ "<div/>"
      class : "kdoverlay transparent"
    @notificationOverlay.hide()
    @notificationOverlay.appendTo "body"
    @notificationOverlay.fadeIn 200
    @notificationOverlay.bind "click",()=>
      @destroy()
  notificationGetOverlay:()-> @notificationOverlay

  notificationSetContent:(content)->
    @notificationContent = content
    @getDomElement().find(".kdnotification-content").removeClass("hidden").html content

  notificationDisplay:()->
    if @getOptions().container
      @getOptions().container.addSubView @
    else
      KDView.appendToDOMBody @
    

