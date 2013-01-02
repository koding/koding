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

  KD.remote.on 'sessionTokenChanged', (token)-> $.cookie 'clientId', token

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

  # Its required for apps
  KD.exportKDFramework()
