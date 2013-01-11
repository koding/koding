class GlobalNotification extends KDView #KDNotificationView
  constructor:(options={},data)->
    options.title ?= 'Shutdown in'
    options.type ?= 'sticky'
    options.targetDate ?= new Date(Date.now()+5*60*1000)
    options.duration = options.targetDate - new Date Date.now()
    options.flashThresholdPercentage ?= 10
    options.flashThresholdSeconds ?= 60
    options.showTimer = yes
    options.content ?= 'We are upgrading the platform. Please save your work.'
    options.bind = 'mouseenter mouseleave'

    super options,data

    @setClass 'notification sticky hidden'

    @on 'mouseenter', =>
      @notificationShowContent()

    @on 'mouseleave', =>
      @notificationHideContent()

    @timer = new KDView
      cssClass : 'notification-timer'
      duration : @getOptions().duration

    @title = new KDView
      cssClass : 'notification-title'
      partial : @getOptions().title

    @contentText = new KDView
      cssClass : 'content'
      partial : @getOptions().content

    @content = new KDView
      cssClass : 'notification-content hidden'

    @content.addSubView @contentText

    @current = new KDView
      cssClass : 'current'

    @startTime = new Date Date.now()
    @endTime = @getOptions().targetDate


  # setDomElement:(cssClass = '')->
  #   @domElement = $ "<div class='kdnotification sticky'>
  #       <a class='kdnotification-close hidden'></a>
  #       <div class='kdnotification-timer hidden'></div>
  #       <div class='kdnotification-title'></div>
  #       <div class='kdnotification-content hidden'></div>
  #     </div>"


    controller = @getSingleton('windowController')
    if controller.stickyNotification
      log 'There already is a notification'
      controller.stickyNotification.show()

    else
      KDView.appendToDOMBody @
      controller.stickyNotification = @

  getCurrentTimeRemaining:->
    @endTime-Date.now()

  getCurrentTimePercentage:->
    overall = @endTime-@startTime
    current = @endTime-Date.now()
    100*current/overall

  pistachio:->
     """
     <div class='header'>
     {{> @timer}}
     </div>
     <div class='slider'>
      {{> @current}}
     </div>
     {{> @content}}
     """

  click:->
    @hide()
    @getSingleton('windowController').stickyNotification = null
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

    @utils.wait =>
      @show()
    @notificationStartTimer @getOptions().duration



  # notificationSetTitle:(title)->
  #   @notificationTitle = title

  # notificationSetContent:(content)->
  #   @notificationContent = content

  # notificationShowTimer:()->
  # notificationSetOverlay:()->
  # notificationSetCloseHandle:->
  # notificationSetTimer:(duration)->

  # notificationDisplay:()->

  notificationShowContent:->
    @content?.show()
    # @contentWrapper?.show()
  notificationHideContent:->
    @content?.hide()
    # @contentWrapper?.hide()


  notificationStartTimer:(duration)->
    return if duration is 0

    timeText = (remaining=300000)->
      seconds = Math.floor remaining/1000
      minutes = Math.floor seconds/60
      if seconds > 0
        if minutes>0
          text = "#{minutes} Minute#{if minutes is 1 then '' else 's'}"
          if seconds-60*minutes isnt 0
            text +=" and #{seconds-60*minutes} seconds"
          text
        else
          "#{seconds} seconds"
      else
        "anytime now."

    # @notificationTimerDiv = @getDomElement().find ".kdnotification-timer"
    @utils.defer =>
      log timeText duration
      # @notificationTimerDiv.text timeText duration
      @timer.updatePartial @getOptions().title+' '+timeText duration
    @notificationTimeout = setTimeout ()=>
      @getDomElement().fadeOut 200,()=>
        @destroy()
    ,duration

    @notificationInterval = setInterval ()=>
      # @notificationTimerDiv.text timeText parseInt(@getOptions().targetDate - new Date(Date.now()),10)
      @current.$().css width : @getCurrentTimePercentage()+'%'
      if @getCurrentTimePercentage() < @getOptions().flashThresholdPercentage or @getCurrentTimeRemaining() < @getOptions().flashThresholdSeconds
        @current.setClass 'flash'
      @timer.updatePartial @getOptions().title+' '+timeText(parseInt(@getOptions().targetDate - new Date(Date.now()),10))
    ,1000

