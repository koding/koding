do ->
  unless KD.config.mainUri?
    KD.config.mainUri = window.location.origin
    KD.config.apiUri  = window.location.origin

  status           = new Status
  mainController   = new MainController
  currentNotif     = null
  firstLoad        = yes

  mainController.tempStorage = {}

  if /edge.koding.com/.test window.location.href
    name = KD.utils.getFullnameFromAccount KD.whoami()
    modal = new KDModalView
      title            : "Hi #{name},"
      width            : 600
      overlay          : yes
      cssClass         : "new-kdmodal"
      content          : """
<div class='modalformline'>
  <p>Thanks for trying out the bleeding 'edge' of Koding features. Most of the new features here are experimental and hence prone to breaking.</p><br>

  <p>If you run into problems, we'd love to hear what went wrong and how to reproduce the error. Please send an email to <a href="mailto:edge@koding.com">edge@koding.com</a>. Note that even though this environment is experimental, your vms are the same production vms as on koding.com.</p><br>

  <p>By continuing you acknowledge the experimental nature of this environment.</p><br>
</div>
"""
      buttons          :
        "I Agree"      :
          style        : "modal-clean-green"
          callback     : -> modal.destroy()

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
    destroyCurrentNotif()
    log 'kd remote connected'

  status.on 'reconnected', (options={})->
    destroyCurrentNotif()
    log "kd remote re-connected"

  status.on 'disconnected', (options={})->
    log "kd remote disconnected"

  KD.remote.connect()

  # Its required for apps
  KD.exportKDFramework()

  ###
  # INTERNET CONNECTIVITIY
  ###

  smallDisconnectedNotif =->
    currentNotif = new KDNotificationView
      title         : "Looks like your Internet Connection is down"
      type          : "tray"
      closeManually : yes
      content       : """<p>Koding will continue trying to reconnect but while your connection is down, <br> no changes you make will be saved back to your VM. Please save your work locally as well.</p>"""
      duration      : 0

  modals =
    small :
      disconnected : smallDisconnectedNotif

  showNotif = (size, state)->
    destroyCurrentNotif()
    modal = modals[size][state]
    modal?()

  destroyCurrentNotif =->
    currentNotif?.destroy()
    currentNotif = null

  if window.navigator.onLine?
    KD.utils.repeat 10000, ->
      if window.navigator.onLine
        destroyCurrentNotif()  if currentNotif
      else
        showNotif "small", "disconnected"  unless currentNotif
  else
    window.connectionCheckerReponse = ->

    KD.utils.repeat 30000, ->
      item = new ConnectionChecker {
        jsonp       : "connectionCheckerReponse"
        crossDomain : yes
        fail        : ->
          showNotif "small", "disconnected"  unless currentNotif
      },
      "https://s3.amazonaws.com/koding-ping/ping.json"

      item.ping -> destroyCurrentNotif()  if currentNotif
