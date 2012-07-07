class NotificationController extends KDObject



  constructor:->

    super

    @getSingleton('mainController').on "AccountChanged", (account)=>
      @setListeners account

  setListeners:(account)->

    nickname = account.getAt('profile.nickname')
    if nickname
      channelName = 'private-'+nickname+'-private'
      bongo.mq.fetchChannel channelName, (channel)=>
        channel.on 'notification', (notification)=>
          @notify notification

  notify: (notification)->

    log notification

    new KDNotificationView
      type     : 'tray'
      cssClass : 'mini realtime'
      title    : 'notification arrived'
      content  : notification.event
      duration : 5000
