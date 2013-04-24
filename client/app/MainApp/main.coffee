#Broker.channel_auth_endpoint = KD.config.apiUri+'/1.0/channel/auth';
#Broker.channel_auth_endpoint = 'http://localhost:8008/auth'

do ->
  status                     = new Status
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

  destroyModal = (reconnected=no, reason="")->
    connectionLostModal?.destroy()
    destroyNotification()

    text =
      silentlyReconnected : "Welcome back!"
      reconnected         : "Server connection has been reset, you can continue working."
      disconnected        : "Server connection has been lost, changes will not be saved until server reconnects, please back up locally."

    reason = text[reason] or text["reconnected"]

    if reconnected isnt no
      new KDNotificationView
        title         : "Reconnected"
        type          : "tray"
        content       : reason
        duration      : 3000
    else
      connectionLostNotification = new KDNotificationView
        title         : "Trying to reconnect..."
        type          : "tray"
        closeManually : no
        content       : reason
        duration      : 0
      connectionLostModal = null

  disconnectionText = (reason)->
    text =
      internetDown : "Your internet connection is down.<br/><br/>"
      kodingDown   : "Sorry, our servers are down temporarily..<br/><br/>"

    return text[reason] or "Something went wrong."

  showModal = (reason) ->
    return if connectionLostModal or manuallyClosed
    destroyNotification()
    connectionLostModal = new KDBlockingModalView
      title   : disconnectionText(reason)
      content : """
      <div class='modalformline'>
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
            destroyModal(no, "disconnected")

    connectionLostModal.once "KDObjectWillBeDestroyed", -> destroyModal(no, "disconnected")

  ###
  # CONNECTIVITY EVENTS
  ###

  status.on 'bongoConnected', (account)->
    KD.socketConnected()
    mainController.accountChanged account
    AccountMixin.init(KD.remote.api)

  status.on 'sessionTokenChanged', (token)-> $.cookie 'clientId', token

  status.on 'connected', ->
    log 'kd remote connected'

  status.on 'reconnected', (reason, showModal)->
    log 'kd remote re-connected'

    modalContent = "silentlyReconnected" unless showModal
    destroyModal yes, modalContent

  status.on 'disconnected', (reason, showModalNotification=yes) ->
    if showModalNotification
      # to avoid modal to appear on page refresh
      __utils.wait 500, showModal(reason)

  KD.remote.connect()

  # Its required for apps
  KD.exportKDFramework()
