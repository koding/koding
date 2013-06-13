class GlobalNotification extends KDView
  constructor:(options={},data)->
    options.title       =   'Shutdown in' if options.title is ''
    options.messageType ?=  options.type
    options.targetDate  ?=  new Date(Date.now()+5*60*1000)
    options.duration    =   new Date(options.targetDate) - new Date Date.now()
    options.flashThresholdPercentage ?= 25
    options.flashThresholdSeconds ?= 60
    options.showTimer   ?=   yes
    options.content     =   'We are upgrading the platform. Please save your work.' if options.content is ''
    options.bind        =   'mouseenter mouseleave'

    super options,data

    @setClass 'notification sticky hidden'

    @setType @getOptions().messageType

    @on 'mouseenter', =>
      # unless @done
        @show()
        @utils.wait 100, =>
          @notificationShowContent()

    @on 'mouseleave', =>
      @notificationHideContent() unless @$().hasClass 'hidden'

    @on 'restartCanceled', =>
      @stopTimer()
      @recalculatePosition()
      @hide()

    @timer     = new KDView
      cssClass : 'notification-timer'
      duration : @getOptions().duration

    @title     = new KDView
      cssClass : 'notification-title'
      partial  : @getOptions().title

    @titleText = @getOptions().title

    @contentText = new KDView
      cssClass : 'content'
      partial  : @getOptions().content

    @content   = new KDView
      cssClass : 'notification-content hidden'

    @content.addSubView @contentText

    @current   = new KDView
      cssClass : 'current'

    @startTime = new Date Date.now()
    @endTime   = new Date @getOptions().targetDate
    @done      = no

    globalSticky = @getSingleton('windowController').stickyNotification

    if globalSticky
      globalSticky.done = no
      globalSticky.setType @getOptions().messageType
      globalSticky.show() unless globalSticky.endTime is Date(@getOptions().targetDate)
      globalSticky.setTitle @getOptions().title
      globalSticky.setContent @getOptions().content
      globalSticky.startTime = Date.now()
      globalSticky.endTime = new Date(@getOptions().targetDate)
      globalSticky.adjustTimer @getOptions().duration

    else
      KDView.appendToDOMBody @
      @getSingleton('windowController').stickyNotification = @

  destroy:->
    super

  show:->
    super
    @getDomElement()[0].style.top = 0

  hide:->
    super
    timerHeight = @$('.slider-wrapper').outerHeight yes

    @$().css top : -@getHeight() + timerHeight

  recalculatePosition:->
    cachedWidth = @getWidth()
    @$().css marginLeft : -cachedWidth/2

  setType:(type='restart')->
    @type = type
    if type is 'restart'
      @showTimer = yes
    else
      @showTimer = no

  setTitle:(title)->
    @title.updatePartial title
    @title.render()
    @titleText = title

  setContent:(content)->
    @contentText.updatePartial content
    @contentText.render()

  stopTimer:->
    clearInterval @notificationInterval
    @$('.slider-wrapper').addClass 'done'
    @timer.updatePartial 'The restart was canceled.'
    # @done = yes

  adjustTimer:(newDuration)->
    if @showTimer
      clearInterval @notificationInterval
      @$('.slider-wrapper').removeClass 'done'
      @$('.slider-wrapper').removeClass 'disabled'
      @notificationStartTimer newDuration
      @recalculatePosition()
    else
      @stopTimer()
      @$('.slider-wrapper').addClass 'disabled'
      @timer.updatePartial @titleText

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
    # @hide() # unless @done
    if @content?.$().hasClass 'hidden'
      @notificationShowContent()
    else
      @notificationHideContent()

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

    controller = @getSingleton('windowController')
    unless controller.stickyNotification
      @utils.defer =>
        @show()
      if @showTimer
        @notificationStartTimer @getOptions().duration
      else
        @timer.updatePartial @getOptions().title
        @$('.slider-wrapper').addClass 'done'

  notificationShowContent:->
    @content?.show()
    @utils.defer =>
      @$('.notification-content').height @contentText.getHeight()

  notificationHideContent:->
    @content?.hide()
    @$('.notification-content').height 0

  notificationStartTimer:(duration)->
    return if duration is 0

    timeText = (remaining=300000,titleText)->
      seconds = Math.floor remaining/1000
      minutes = Math.floor seconds/60
      if seconds > 0
        text = titleText+' '
        if minutes>0
          text += "#{minutes} Minute#{if minutes is 1 then '' else 's'}"
          if seconds-60*minutes isnt 0
            text +=" and #{seconds-60*minutes} seconds"
          text
        else
          text += "#{seconds} second#{if seconds isnt 1 then 's' else ''}"
      else
        "Shutting down anytime now."

    @timer.updatePartial timeText duration, @titleText

    @notificationInterval = setInterval ()=>
      currentTimePercentage = @getCurrentTimePercentage()
      options = @getOptions()
      @current.getDomElement()[0].style.width = currentTimePercentage+'%'
      if (currentTimePercentage < options.flashThresholdPercentage) \
      or (@getCurrentTimeRemaining()/1000 < options.flashThresholdSeconds)
        @current.setClass 'flash'
      else @current.unsetClass 'flash'
      currentTime = parseInt(@endTime - Date.now(),10)
      @timer.updatePartial timeText currentTime, @titleText

      @recalculatePosition()
      if currentTime < 0
        @done = yes
        clearInterval @notificationInterval
        @$('.slider-wrapper').addClass 'done'
    ,1000

