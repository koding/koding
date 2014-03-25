class KiteHelper extends KDEventEmitter

  constructor:->
    super
    @attachListeners()

  attachListeners:->
    mainController = KD.getSingleton("mainController")

    mainController.on "pageLoaded.as.loggedIn", (account)=> # ignore othter parameters
      @emit "changedToLoggedIn"

    mainController.on "accountChanged.to.loggedIn", (account)=> # ignore othter parameters
      @emit "changedToLoggedIn"

    @once "changedToLoggedIn", @registerKodingClient


  clear = ->
    Cookies.expire "register-to-koding-client"
    KD.getSingleton("router").clear()

  @initiateRegistiration : ->
    Cookies.set "register-to-koding-client", yes
    unless KD.isLoggedIn()
      message = "Please login to proceed to the next step"
      modal = new KDBlockingModalView
        title        : "Koding Client Registration"
        content      : "<div class='modalformline'>#{message}</div>"
        height       : "auto"
        overlay      : yes
        buttons      :
          "Go to Login" :
            style       : "modal-clean-gray"
            callback    : ->
              modal.destroy()
              KD.utils.wait 5000, KD.getSingleton("router").handleRoute "/Login"
          "Cancel" :
            style       : "modal-cancel"
            callback    : ->
              modal.destroy()
              clear()

    else
      KD.getSingleton("router").clear()
      registerKodingClient_()

  registerKodingClient_ = ->
    if registerToKodingClient = Cookies.get "register-to-koding-client"
      clear()
      # We pick up 54321 because it's in dynamic range and no one uses it
      # http://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
      k = new NewKite
        name: "kodingclient"
        publicIP: "127.0.0.1"
        port: "54321"

      k.connect()

      showErrorModal = (error, callback)->
        {message, code} = error
        modal = new KDBlockingModalView
          title        : "Kite Registration"
          content      : "<div class='modalformline'>#{message}</div>"
          height       : "auto"
          overlay      : yes
          buttons      : {}

        Retry      =
          style    : "modal-clean-gray"
          callback : ->
            modal.destroy()
            callback?()

        Cancel     =
          style    : "modal-clean-red"
          callback : ->
            modal.destroy()
            clear()

        Ok         =
          style    : "modal-clean-gray"
          callback : ->
            modal.destroy()
            clear()

        if code is 201
          modal.setButtons {Ok}, yes
        else
          modal.setButtons {Retry, Cancel}, yes

      showSuccessfulModal = (message, callback)->
        modal = new KDBlockingModalView
          title        : "Koding Client Registration"
          content      : "<div class='modalformline'>#{message}</div>"
          height       : "auto"
          overlay      : yes
          buttons      :
            Ok         :
              style    : "modal-clean-green"
              callback : ->
                modal.destroy()
                callback?()

      handleInfo = (err, result)->
        KD.remote.api.JKodingKey.registerHostnameAndKey {
            key:result.key
            hostname:result.hostID
        }, (err, res)->
          fn = => k.tellOld "info", handleInfo
          return showErrorModal err, fn if err
          showSuccessfulModal res, ->
            result.cb true
            KD.utils.wait 500, clear

      k.tellOld "info", handleInfo

  registerKodingClient : registerKodingClient_
