class GlobalNotification extends KDNotificationView
  constructor:(options={},data)->
    options.title = 'Shutdown in'
    options.type ?= 'sticky'
    options.targetDate ?= new Date(Date.now()+5*60*1000)
    options.duration = options.targetDate - new Date Date.now()
    options.showTimer = yes

    super options,data

  setDomElement:(cssClass = '')->
    @domElement = $ "<div class='kdnotification sticky'>
        <a class='kdnotification-close hidden'></a>
        <div class='kdnotification-timer hidden'></div>
        <div class='kdnotification-title'></div>
        <div class='kdnotification-content hidden'></div>
      </div>"


  notificationShowTimer:()->
    @notificationTimerDiv.removeClass "hidden"


  notificationSetTimer:(duration)->
    log duration
    return if duration is 0

    timeText = (remaining=300000)->
      seconds = Math.floor remaining/1000
      minutes = Math.floor seconds/60
      log seconds, minutes
      if minutes>0
        "#{minutes} Minute#{if minutes is 1 then '' else 's'} and #{seconds-60*minutes} seconds"
      else
        "#{seconds} seconds"

    @notificationTimerDiv = @getDomElement().find ".kdnotification-timer"
    @utils.defer => @notificationTimerDiv.text timeText timeText duration

    @notificationTimeout = setTimeout ()=>
      @getDomElement().fadeOut 200,()=>
        @destroy()
    ,duration

    @notificationInterval = setInterval ()=>
      @notificationTimerDiv.text timeText parseInt(@getOptions().targetDate - new Date(Date.now()),10)
    ,1000
