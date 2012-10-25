#Broker.channel_auth_endpoint = KD.config.apiUri+'/1.0/channel/auth';
#Broker.channel_auth_endpoint = 'http://localhost:8008/auth'

do ->
  mainController             = new MainController
  firstLoad                  = yes
  connectionLostModal        = null
  connectionLostNotification = null
  manuallyClosed             = no

  destroyNotification = ->
    connectionLostNotification?.destroy()
    connectionLostNotification = null

  # destroyConnectionSetNotification = ->
  #   connectionSetNotification?.destroy()
  #   connectionSetNotification = null

  destroyModal = (reconnected = no)->
    connectionLostModal?.destroy()
    destroyNotification()
    if reconnected isnt no
      new KDNotificationView
        title         : "Reconnected"
        type          : "tray"
        content       : "Server connection has been reset, you can continue working."
        duration      : 3000
    else
      connectionLostNotification = new KDNotificationView
        title         : "Trying to reconnect..."
        type          : "tray"
        closeManually : no
        content       : "Server connection has been lost, changes will not be saved until server reconnects, please back up locally."
        duration      : 0
      connectionLostModal = null

  showModal = ->
    return if connectionLostModal or manuallyClosed
    destroyNotification()
    connectionLostModal = new KDBlockingModalView
      title   : "Server connection lost"
      content : """
        <div class='modalformline'>
          Your internet connection may be down, or our server is.<br/><br/>
          If you have unsaved work please close this dialog and <br/><strong>back up your unsaved work locally</strong> until the connection is re-established.<br/><br/>
          <span class='small-loader fade in'></span> Trying to reconnect...
        </div>
        """
      height  : "auto"
      overlay : yes
      buttons :
        "Close and work offline" :
          style     : "modal-clean-red"
          callback  : ->
            manuallyClosed = yes
            destroyModal()

    connectionLostModal.once "KDObjectWillBeDestroyed", -> destroyModal()

  ###
  # CONNECTIVITY EVENTS
  ###

  KD.remote.on 'loggedInStateChanged', (account)->
    KD.socketConnected()
    mainController.accountChanged account
    AccountMixin.init(KD.remote.api)


  KD.remote.on 'connected', ->
    manuallyClosed = no
    if firstLoad
      log 'kd remote connected'
      firstLoad = no
    else
      log 'kd remote re-connected'
      destroyModal yes

  KD.remote.on 'disconnected', ->
    # to avoid modal to appear on page refresh
    __utils.wait 500, showModal

  KD.remote.connect()


  #initConnectionEvents conn
#
#  if connectionLostModalId?
#    (KDModalController.getModalById connectionLostModalId)?.destroy()
#    connectionLostModalId = null
#
#    # THE MODAL APPEARS WHEN CONNECTION IS RE-ESTABLISHED
#    connectionLostModalId = KDModalController.createAndShowNewModal
#      type    : 'blocking'
#      title   : "Server connection <i style='color:green;'>established!</i>"
#      content : """
#        <div class='modalformline'>
#          <strong style='color:green;'>Connection re-established,</strong><br/><br/>
#          If you have unsaved work please close this dialog and <br/><strong>back up your unsaved work locally</strong> then refresh the page!
#        </div>
#        """
#      height  : "auto"
#      overlay : yes
#      buttons :
#        "Refresh Now" :
#          style     : "modal-clean-red"
#          callback  : ()->
#            @propagateEvent KDEventType:'KDModalShouldClose'
#            connectionLostModalId = null
#            location.reload yes
#        "Refresh Later" :
#          style     : "modal-cancel"
#          callback  : ()->
#            @propagateEvent KDEventType:'KDModalShouldClose'
#            connectionLostModalId = null
#            if connectionLostNotification?
#              connectionLostNotification.destroy()
#              connectionLostNotification = null
#            updateModalActive = no
#            # THE NOTIFICATION APPEARS WHEN MODAL WAS CLOSED AFTER CONNECTION RE-ESTABLISHES
#            connectionLostNotification = new KDNotificationView
#              title    : "Please back up your work and refresh!"
#              content  : "Changes will not be saved until you refresh the page."
#              duration : 999999999
#
#  if connectionLostNotification?
#    connectionLostNotification.destroy()
#    connectionLostNotification = null
#    # THE NOTIFICATION APPEARS WHEN MODAL WAS CLOSED BEFORE CONNECTION RE-ESTABLISHES
#    # IS BEING UPDATED TO A NEW RE-ESTABLISHED NOTIFICATION
#    connectionLostNotification = new KDNotificationView
#      title    : "Connection re-established!"
#      content  : "If you backed up you can refresh now, changes will not be saved until you refresh."
#      duration : 999999999
#
#  #
#  # CONNECTIVITY NOTIFICATIONS PART END
#  #
#
#  if firstLoad
#    # Cacheable.init()
#    api.JVisitor = class JVisitor extends api.JVisitor
#      constructor:(options)->
#        super()
#        if options.startListening
#          @start (err)->
#            throw err if err
#
#    Bongo.Model::fetchPrivateChannel = do ->
#      {JChannel} = api
#      channels = []
#      (callback)->
#        JChannel.fetch "#{@getId()}_private", (err, secretChannelId)=>
#          if err
#            callback err
#          else if secretChannelId?
#            if channel = channels[secretChannelId]
#              callback null, channel
#            else
#              channel = @mq.subscribe secretChannelId
#              channels[secretChannelId] = channel
#              callback null, channel
#          else callback new KodingError 'bad user!'
#
#    AccountMixin.init(api)
#
#    mainController.setVisitor new api.JVisitor startListening: yes
#
#    cyclePrivateChannel =(delegate)->
#      KD.remote.api.JChannel.fetch delegate.getId()+'_private', (err, channelId)->
#        channel = KD.remote.mq?.subscribe channelId
#        channel.bind 'change.channel', ->
#          KD.remote.mq.unsubscribe channelId
#          cyclePrivateChannel delegate
#        ###channel.bind 'message', (msg)->
#          log msg###
#
#    changeLoginState = (delegate)->
#      cyclePrivateChannel(delegate)
#      mainController.getVisitor().currentDelegate = delegate
#
#    mainController.getVisitor().on 'change.login', changeLoginState
#    mainController.getVisitor().on 'change.logout', changeLoginState
#
#    KD.socketConnected()
#    firstLoad = no
#
#  updateModalActive = no
#  KD.remote.api.JVisitor.getVersion (err, version)->
#    return if KD.version is version or updateModalActive
#    updateModalActive = yes
#
#    modal = new KDBlockingModalView
#      title   : "There is a new version available!"
#      content : "<div class='modalformline'>Please save your work and refresh!
#                  <br><br><span class='small-loader fade in'></span> Please report bugs in the update to the beta feedback site</div>"
#      height  : "auto"
#      overlay : yes
#      buttons :
#        "Refresh Now" :
#          style     : "modal-clean-red"
#          callback  : ()->
#            modal.destroy()
#            location.reload yes
#        "Refresh Later" :
#          style     : "modal-cancel"
#          callback  : ()->
#            modal.destroy()
#            updateModalActive = no
#

# if location.hostname is "localhost"
#   a = setInterval ->
#     myVal = localStoragejsReloaderLastReload
#     $.get "/js/requiresReload.txt",(response)->
#       if response is "0"
#         clearInterval a
#       else
#         if response isnt myVal
#           localStorage.jsReloaderLastReload = response
#           a = new KDNotificationView
#             type : "growl"
#             title : "Oh no, I'm going down..."
#             duration : 500
#           location.reload yes
#
#           #
#           # BSOD SECTION :)
#           #
#           # setTimeout ->
#           #   location.assign "http://localhost:3000:/bsod.html"
#           # ,1000
#           #
#
#   ,1000
