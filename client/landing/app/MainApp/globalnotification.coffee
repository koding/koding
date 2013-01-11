class GlobalNotification extends KDView #KDNotificationView
  constructor:(options={},data)->
    options.title ?= 'Shutdown in'
    options.type ?= 'sticky'
    options.targetDate ?= new Date(Date.now()+5*60*1000)
    options.duration = options.targetDate - new Date Date.now()
    options.flashThresholdPercentage ?= 25
    options.flashThresholdSeconds ?= 60
    options.showTimer = yes
    options.content ?= 'We are upgrading the platform. Please save your work.'
    options.bind = 'mouseenter mouseleave'

    super options,data

    @setClass 'notification sticky hidden'

    @on 'mouseenter', =>
      @show()
      @notificationShowContent()

    @on 'mouseleave', =>
      @notificationHideContent() unless @$().hasClass 'hidden'

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
     <span class='icon'></span>
     {{> @timer}}
     </div>

     {{> @content}}

     <div class='slider-wrapper'>
       <div class='slider'>
        {{> @current}}
       </div>
     </div>
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

  notificationShowContent:->
    @content?.show()
  notificationHideContent:->
    @content?.hide()

  notificationStartTimer:(duration)->
    return if duration is 0

    timeText = (remaining=300000)=>
      seconds = Math.floor remaining/1000
      minutes = Math.floor seconds/60
      if seconds > 0
        text = @getOptions().title+' '
        if minutes>0
          text += "#{minutes} Minute#{if minutes is 1 then '' else 's'}"
          if seconds-60*minutes isnt 0
            text +=" and #{seconds-60*minutes} seconds"
          text
        else
          text += "#{seconds} second#{if seconds isnt 1 then 's' else ''}"
      else
        "Shutting down anytime now."

    @utils.defer =>
      @timer.updatePartial timeText duration

    @notificationInterval = setInterval ()=>
      @current.$().css width : @getCurrentTimePercentage()+'%'
      if (@getCurrentTimePercentage() < @getOptions().flashThresholdPercentage) \
      or (@getCurrentTimeRemaining()/1000 < @getOptions().flashThresholdSeconds)
        @current.setClass 'flash'
      currentTime = parseInt(@getOptions().targetDate - new Date(Date.now()),10)
      @timer.updatePartial timeText currentTime
      if currentTime < 0
        clearInterval @notificationInterval
        @$('.slider-wrapper').addClass 'done'
    ,1000

