class MainController extends KDController

  ###

  * EMITTED EVENTS
    - AppIsReady
    - AccountChanged                [account, firstLoad]
    - pageLoaded.as.loggedIn        [account, connectedState, firstLoad]
    - pageLoaded.as.loggedOut       [account, connectedState, firstLoad]
    - accountChanged.to.loggedIn    [account, connectedState, firstLoad]
    - accountChanged.to.loggedOut   [account, connectedState, firstLoad]
  ###

  connectedState =
    connected   : no

  constructor:(options = {}, data)->

    options.failWait  = 5000            # duration in miliseconds to show a connection failed modal

    super options, data

    @appStorages = {}

    @createSingletons()
    @setFailTimer()
    @attachListeners()

    @introductionTooltipController = new IntroductionTooltipController

  createSingletons:->

    KD.registerSingleton "mainController",            this
    KD.registerSingleton "windowController",          new KDWindowController
    KD.registerSingleton "appManager",   appManager = new ApplicationManager
    KD.registerSingleton "kiteController",            new KiteController
    KD.registerSingleton "vmController",              new VirtualizationController
    KD.registerSingleton "contentDisplayController",  new ContentDisplayController
    KD.registerSingleton "notificationController",    new NotificationController
    KD.registerSingleton "paymentController",         new PaymentController
    KD.registerSingleton "linkController",            new LinkController
    KD.registerSingleton 'router',           router = new KodingRouter location.pathname

    # KD.registerSingleton "localStorageController", new LocalStorageController
    # KD.registerSingleton "fatih", new Fatih

    appManager.create 'Groups', (groupsController)->
      KD.registerSingleton "groupsController", groupsController

    appManager.create 'Chat', (chatController)->
      KD.registerSingleton "chatController", chatController

    @ready =>
      router.listen()
      KD.registerSingleton "activityController",   new ActivityController
      KD.registerSingleton "appStorageController", new AppStorageController
      KD.registerSingleton "kodingAppsController", new KodingAppsController
      @emit 'AppIsReady'

  accountChanged:(account, firstLoad = no)->
    @userAccount             = account
    connectedState.connected = yes

    KD.whoami().fetchMyPermissionsAndRoles (err, permissions, roles)=>
      return warn err  if err
      KD.config.roles       = roles
      KD.config.permissions = permissions

      @ready @emit.bind @, "AccountChanged", account, firstLoad

      @createMainViewController()  unless @mainViewController

      @decorateBodyTag()
      @emit 'ready'

      # this emits following events
      # -> "pageLoaded.as.loggedIn"
      # -> "pageLoaded.as.loggedOut"
      # -> "accountChanged.to.loggedIn"
      # -> "accountChanged.to.loggedOut"
      eventPrefix = if firstLoad then "pageLoaded.as" else "accountChanged.to"
      eventSuffix = if @isUserLoggedIn() then "loggedIn" else "loggedOut"
      @emit "#{eventPrefix}.#{eventSuffix}", account, connectedState, firstLoad

  createMainViewController:->
    @loginScreen = new LoginView
    KDView.appendToDOMBody @loginScreen
    @mainViewController  = new MainViewController
      view    : mainView = new MainView
        domId : "kdmaincontainer"
    KDView.appendToDOMBody mainView

  doLogout:->

    KD.logout()
    KD.remote.api.JUser.logout (err, account, replacementToken)=>
      $.cookie 'clientId', replacementToken if replacementToken
      @accountChanged account

    # fixme: make a old tv switch off animation and reload
    # $('body').addClass "turn-off"
    return location.reload()

  attachListeners:->

    # @on 'pageLoaded.as.(loggedIn|loggedOut)', (account)=>
    #   log "pageLoaded", @isUserLoggedIn()


  # some day we'll have this :)
  hashDidChange:(params,query)->

  setVisitor:(visitor)-> @visitor = visitor
  getVisitor: -> @visitor
  getAccount: -> KD.whoami()

  isUserLoggedIn: -> KD.whoami() instanceof KD.remote.api.JAccount

  unmarkUserAsTroll:(data)->

    kallback = (acc)=>
      acc.unflagAccount "exempt", (err, res)->
        if err then warn err
        else
          new KDNotificationView
            title : "@#{acc.profile.nickname} won't be treated as a troll anymore!"

    if data.originId
      KD.remote.cacheable "JAccount", data.originId, (err, account)->
        kallback account if account
    else if data.bongo_.constructorName is 'JAccount'
      kallback data

  markUserAsTroll:(data)->

    modal = new KDModalView
      title          : "MARK USER AS TROLL"
      content        : """
                        <div class='modalformline'>
                          This is what we call "Trolling the troll" mode.<br><br>
                          All of the troll's activity will disappear from the feeds, but the troll
                          himself will think that people still gets his posts/comments.<br><br>
                          Are you sure you want to mark him as a troll?
                        </div>
                       """
      height         : "auto"
      overlay        : yes
      buttons        :
        "YES, THIS USER IS DEFINITELY A TROLL" :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            kallback = (acc)=>
              acc.flagAccount "exempt", (err, res)->
                if err then warn err
                else
                  modal.destroy()
                  new KDNotificationView
                    title : "@#{acc.profile.nickname} marked as a troll!"

            if data.originId
              KD.remote.cacheable "JAccount", data.originId, (err, account)->
                kallback account if account
            else if data.bongo_.constructorName is 'JAccount'
              kallback data

  blockUser:(accountId, duration, callback)->
    KD.whoami().blockUser accountId, duration, callback

  openBlockUserModal:(data)->
    @modal = modal = new KDModalViewWithForms
      title                   : "Block User For a Time Period"
      content                 : """
                                <div class='modalformline'>
                                  This will block user from logging in to Koding(with all sub-groups).<br><br>
                                  You can specify a duration to block user.
                                </div>
                                """
      overlay                 : yes
      cssClass                : "modalformline"
      width                   : 500
      height                  : "auto"
      tabs                    :
        forms                 :
          BlockUser           :
            callback          : =>
              blockingTime = calculateBlockingTime modal.modalTabs.forms.BlockUser.inputs.duration.getValue()
              @blockUser data.originId, blockingTime, (err, res)->
                if err
                  warn err
                  modal.modalTabs.forms.BlockUser.buttons.blockUser.hideLoader()
                else
                  modal.destroy()
                  new KDNotificationView title : "User is blocked!"

            buttons           :
              blockUser       :
                title         : "Block User"
                style         : "modal-clean-gray"
                type          : "submit"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : -> @hideLoader()
              cancel          :
                title         : "Cancel"
                style         : "modal-cancel"
            fields            :
              duration        :
                label         : "Block User For"
                itemClass     : KDInputView
                name          : "duration"
                placeholder   : "e.g. 1Y 1W 3D 2H..."
                keyup         : ->
                  changeButtonTitle @getValue()
                change        : ->
                  changeButtonTitle @getValue()
                validate             :
                  rules              :
                    required         : yes
                    minLength        : 2
                    regExp           : /\d[A-Za-z]+/i
                  messages           :
                    required         : "Please enter a time period"
                    minLength        : "You must enter one pair"
                    regExp           : "You must enter at least a number and a character e.g : 1y 1h"
                iconOptions          :
                  tooltip            :
                    placement        : "right"
                    offset           : 2
                    title            : """
                                       You can enter {#}H/D/W/M/Y,
                                       Order is not sensitive.
                                       """
    form = modal.modalTabs.forms.BlockUser
    form.on "FormValidationFailed", ->
    form.buttons.blockUser.hideLoader()

    changeButtonTitle = (value)->
      blockingTime = calculateBlockingTime value
      button = modal.modalTabs.forms.BlockUser.buttons.blockUser
      if blockingTime > 0
        date = new Date (Date.now() + blockingTime)
        button.setTitle "Block User to: #{date.toUTCString()}"
      else
        button.setTitle "Block User"


    calculateBlockingTime = (value)->

      totalTimestamp = 0
      unless value then return totalTimestamp
      for val in value.split(" ")
        # this is the first part of blocking time
        # if val 2D then numericalValue will be 2
        numericalValue = parseInt(val.slice(0, -1), 10) or 0
        if numericalValue is 0 then continue
        hour = numericalValue * 60 * 60 * 1000
        # we will get the lastest part of val as time case
        timeCase = val.charAt(val.length-1)
        switch timeCase.toUpperCase()
          when "H"
            totalTimestamp = hour
          when "D"
            totalTimestamp = hour * 24
          when "W"
            totalTimestamp = hour * 24 * 7
          when "M"
            totalTimestamp = hour * 24 * 30
          when "Y"
            totalTimestamp = hour * 24 * 365

      return totalTimestamp


  decorateBodyTag:->
    if KD.checkFlag 'super-admin'
    then $('body').addClass 'super'
    else $('body').removeClass 'super'

  setFailTimer: do->
    modal = null
    fail  = ->
      modal = new KDBlockingModalView
        title   : "Couldn't connect to the backend!"
        content : "<div class='modalformline'>
                     We don't know why, but your browser couldn't reach our server.<br><br>Please try again.
                   </div>"
        height  : "auto"
        overlay : yes
        buttons :
          "Refresh Now" :
            style     : "modal-clean-red"
            callback  : ->
              modal.destroy()
              location.reload yes
      # if location.hostname is "localhost"
      #   KD.utils.wait 5000, -> location.reload yes

    checkConnectionState = ->
      unless connectedState.connected
        fail()

        #KD.logToMixpanel "Couldn't connect to backend"
    ->
      @utils.wait @getOptions().failWait, checkConnectionState
      @on "AccountChanged", =>
        if modal
          modal.setTitle "Connection Established"
          modal.$('.modalformline').html "<b>It just connected</b>, don't worry about this warning."
          @utils.wait 2500, -> modal?.destroy()
