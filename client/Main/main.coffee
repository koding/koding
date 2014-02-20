do ->
  status           = new Status
  mainController   = new MainController
  modalTimerId     = null
  currentModal     = null
  currentModalSize = null
  firstLoad        = yes

  mainController.tempStorage = {}

  ###
  # CONNECTIVITY EVENTS
  ###

  status.on 'bongoConnected', (account)->
    KD.socketConnected()
    mainController.accountChanged account, firstLoad
    firstLoad = no

  status.on 'sessionTokenChanged', (token)->
    # this is disabled for now to test user log-out problem.
    # $.cookie 'clientId', token

  status.on 'connected', ->
    destroyCurrentModal()
    log 'kd remote connected'

  status.on 'reconnected', (options={})->
    destroyCurrentModal()

    modalSize  = options.modalSize  or= "big"
    notifyUser = options.notifyUser or= "yes"
    state      = "reconnected"

    log "kd remote re-connected, modalSize: #{modalSize}"

    clearTimeout modalTimerId
    modalTimerId = null

    modalSize  = currentModalSize or options.modalSize
    notifyUser = options.notifyUser

    if notifyUser or currentModal
      currentModal = showModal modalSize, state

  status.on 'disconnected', (options={})->
    reason     = options.reason     or= "unknown"
    modalSize  = options.modalSize  or= "big"
    notifyUser = options.notifyUser or= "yes"
    state      = "disconnected"

    KD.logToExternalWithTime "User disconnected"

    log "disconnected",\
    "reason: #{reason}, modalSize: #{modalSize}, notifyUser: #{notifyUser}"

    if notifyUser
      # timeout to prevent user from seeing minor interruptions
      # if reconnected within 2 secs, reconnected event clears this
      modalTimerId = setTimeout =>
        currentModalSize = modalSize
        # in Status class there is constants that we can not
        # reach from another class here o_0
        # 4 represents disconnected state
        return if status.state isnt 4
        # disable modal
        # currentModal = showModal modalSize, state
      , 2000

    currentModalSize = "small"

  KD.remote.connect()

  # Its required for apps
  KD.exportKDFramework()

  ###
  # CONNECTIVITIY MODALS
  ###

  bigDisconnectedModal =->
    currentModal = new KDBlockingModalView
      title   : "Something went wrong."
      content : """
        Your internet connection may be down or our servers are down temporarily.<br/><br/>
        If you have unsaved work please close this dialog and <br/><strong>back up your unsaved work locally</strong> until the connection is re-established.<br/><br/>
        <span class='small-loader fade in'></span> Trying to reconnect...
      """
      height  : "auto"
      overlay : yes
      buttons :
        "Close and work offline" :
          style     : "modal-clean-red"
          callback  : ->
            showModal "small", "disconnected"

  smallDisconnectedModal =->
    currentModal = new KDNotificationView
      title         : "Trying to reconnect..."
      type          : "tray"
      closeManually : no
      content       : "Server connection has been lost, changes will not be saved until server reconnects, please back up locally."
      duration      : 0

  bigReconnectedModal =->
    currentModal = new KDNotificationView
      title         : "Reconnected"
      type          : "tray"
      content       : "Server connection has been reset, you can continue working."
      duration      : 3000

  smallReconnectedModal =->
    currentModal = new KDNotificationView
      title     : "<span></span>Reconnected, Welcome Back!"
      type      : "tray"
      cssClass  : "small realtime"
      duration  : 3303

  modals =
    big   :
      disconnected    : smallDisconnectedModal
      reconnected     : smallReconnectedModal
    small :
      disconnected    : smallDisconnectedModal
      reconnected     : smallReconnectedModal
      disconnectedMin : smallDisconnectedModal

  showModal = (size, state)->
    destroyCurrentModal()
    currentModalSize = size
    modal = modals[size][state]
    modal?()

  destroyCurrentModal =->
    currentModal?.destroy()
    currentModal = null
