class OldLoginView extends KDScrollView

  stop =(event)->
    event.preventDefault()
    event.stopPropagation()

  constructor:(options = {}, data)->


    {entryPoint} = KD.config

    super options, data

    @hidden = no

    handler =(route, event)=>
      stop event
      @getSingleton('router').handleRoute route, {entryPoint}

    homeHandler       = handler.bind null, '/'
    learnMoreHandler  = handler.bind null, '/Join'
    loginHandler      = handler.bind null, '/Login'
    registerHandler   = handler.bind null, '/Register'
    joinHandler       = handler.bind null, '/Join'
    recoverHandler    = handler.bind null, '/Recover'

    @logo = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "logo"
      lazyDomId   : "header-logo"
      partial     : "Koding"
      click       : homeHandler

    @backToVideoLink = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "video-link"
      partial     : "video again?"
      click       : homeHandler

    @backToLoginLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Go ahead and login"
      click       : loginHandler

    @goToRequestLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Request an invite"
      click       : joinHandler

    @goToRegisterLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Register an account"
      click       : registerHandler

    @bigLinkReg = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Register"
      click       : registerHandler

    @bigLinkReq = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Request an Invite"
      click       : joinHandler

    @bigLinkLog = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Login"
      click       : loginHandler

    @bigLinkLearn = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Learn more"
      click       : => @$().animate scrollTop : 1200

    @goToRecoverLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Recover password"
      click       : recoverHandler

    @loginForm = new LoginInlineForm
      lazyDomId: "login-form"
      cssClass : "login-form"
      callback : (formData)=>
        formData.clientId = $.cookie('clientId')
        @doLogin formData

    @registerForm = new RegisterInlineForm
      lazyDomId: "register-form"
      cssClass : "login-form"
      callback : (formData)=> @doRegister formData

    @recoverForm = new RecoverInlineForm
      lazyDomId: "recover-form"
      cssClass : "login-form"
      callback : (formData)=> @doRecover formData

    @resetForm = new ResetInlineForm
      lazyDomId: "reset-form"
      cssClass : "login-form"
      callback : (formData)=>
        formData.clientId = $.cookie('clientId')
        @doReset formData

    @requestForm = new RequestInlineForm
      lazyDomId: "request-form"
      cssClass : "login-form"
      callback : (formData)=> @doRequest formData

    @headBanner = new KDCustomHTMLView
      lazyDomId: "invite-recovery-notification-bar"
      cssClass : "invite-recovery-notification-bar hidden"
      partial  : "..."

    @slideShow = new HomeSlideShowHolder
      lazyDomId : 'home-screenshots'

  viewAppended:->

    @listenWindowResize()
    @setClass "home-links"
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      <p class='bigLink'>{{> @bigLinkReq}}</p>
      <p class='bigLink'>{{> @bigLinkReg}}</p>
      <p class='bigLink'>{{> @bigLinkLog}}</p>
      <p class='bigLink'>{{> @bigLinkLearn}}</p>
      <p class='reqLink'>Want to get in? {{> @goToRequestLink}}</p>
      <p class='regLink'>Have an invite? {{> @goToRegisterLink}}</p>
      <p class='logLink'>Already a user? {{> @backToLoginLink}}</p>
      <p class='recLink'>Trouble logging in? {{> @goToRecoverLink}}</p>
      <p class='vidLink'>Want to watch the {{> @backToVideoLink}}</p>
    """

  doReset:({recoveryToken, password, clientId})->
    KD.remote.api.JPasswordRecovery.resetPassword recoveryToken, password, (err, username)=>
      @resetForm.button.hideLoader()
      @resetForm.reset()
      @headBanner.hide()
      @doLogin {username, password, clientId}

  doRecover:(formData)->
    KD.remote.api.JPasswordRecovery.recoverPassword formData['username-or-email'], (err)=>
      @recoverForm.button.hideLoader()
      if err
        new KDNotificationView
          title : "An error occurred: #{err.message}"
      else
        @animateToForm "login"
        new KDNotificationView
          title     : "Check your email"
          content   : "We've sent you a password recovery token."
          duration  : 4500

  doRegister:(formData)->
    {kodingenUser} = formData
    formData.agree = 'on'
    @registerForm.notificationsDisabled = yes
    @registerForm.notification?.destroy()

    KD.remote.api.JUser.register formData, (error, account, replacementToken)=>
      @registerForm.button.hideLoader()
      if error
        {message} = error
        @registerForm.notificationsDisabled = no
        @registerForm.emit "SubmitFailed", message
      else
        $.cookie 'clientId', replacementToken
        @getSingleton('mainController').accountChanged account
        new KDNotificationView
          cssClass  : "login"
          title     : if kodingenUser then '<span></span>Nice to see an old friend here!' else '<span></span>Good to go, Enjoy!'
          # content   : 'Successfully registered!'
          duration  : 2000
        KD.getSingleton('router').clear()
        setTimeout =>
          @animateToForm "login"
          @registerForm.reset()
          @registerForm.button.hideLoader()
          # setTimeout =>
          #   @getSingleton('mainController').emit "ShowInstructionsBook"
          # , 1000
        , 1000

  doLogin:(credentials)->
    credentials.username = credentials.username.toLowerCase()
    KD.remote.api.JUser.login credentials, (error, account, replacementToken) =>
      @loginForm.button.hideLoader()
      if error
        new KDNotificationView
          title   : error.message
          duration: 1000
        @loginForm.resetDecoration()
      else
        $.cookie 'clientId', replacementToken  if replacementToken
        @getSingleton('mainController').accountChanged account
        @getSingleton('router').handleRoute null, replaceState: yes

        new KDNotificationView
          cssClass  : "login"
          title     : "<span></span>Happy Coding!"
          # content   : "Successfully logged in."
          duration  : 2000
        @loginForm.reset()

  doRequest:(formData)->

    KD.remote.api.JInvitationRequest.create formData, (err, result)=>

      if err
        msg = if err.code is 11000 then "This email was used for a request before!"
        else "Something went wrong, please try again!"
        new KDNotificationView
          title     : msg
          duration  : 2000
      else
        @requestForm.reset()
        @requestForm.email.hide()
        @requestForm.button.hide()
        @$('.flex-wrapper').addClass 'expanded'
      @requestForm.button.hideLoader()

  showHeadBanner:(message, callback)->
    @hide()
    @headBannerMsg = message
    @headBanner.updatePartial @headBannerMsg
    @headBanner.unsetClass 'hidden'
    @headBanner.setClass 'show'
    $('body').addClass 'recovery'
    @headBanner.click = callback

  headBannerShowGoBackGroup:(groupTitle)->
    @showHeadBanner "<span>Go Back to</span> #{groupTitle}", =>
      @headBanner.hide()
      $('#group-landing').css 'height', '100%'
      $('#group-landing').css 'opacity', 1

  headBannerShowRecovery:(recoveryToken)->

    @showHeadBanner "Hi, seems like you came here to reclaim your account. <span>Click here when you're ready!</span>", =>
      @getSingleton('router').clear '/Recover/Password'
      @headBanner.updatePartial "You can now create a new password for your account"
      @resetForm.addCustomData {recoveryToken}
      @animateToForm "reset"

  handleInvitation:(invite)->
    @headBannerShowInvitation invite

  headBannerShowInvitation:(invite)->

    @showHeadBanner "Cool! you got an invite! <span>Click here to register your account.</span>", =>
      @headBanner.hide()
      @getSingleton('router').clear '/Register'
      $('body').removeClass 'recovery'
      @showView =>
        @animateToForm "register"
        @getSingleton('mainController').emit 'InvitationReceived', invite

  hideView:(callback)->

    {winHeight} = @getSingleton("windowController")

    # @$().css marginTop : -winHeight
    $('#main-form-handler').css marginTop : -winHeight

    @utils.wait 601, =>
      @hidden = yes
      # $('#main-form-handler').addClass 'hidden'
      callback?()

  showView:(callback)->

    # $('#main-form-handler').removeClass 'hidden'

    # @$().css marginTop : 0
    $('#main-form-handler').css marginTop : 0

    @utils.wait 601, =>
      @hidden = no
      callback?()

  _windowDidResize:(event)->

    if @hidden
      {winWidth,winHeight} = @getSingleton("windowController")
      $('#main-form-handler').css marginTop : -winHeight

  animateToForm: (name)->

    switch name
      when "register"
        # @utils.wait 5000, =>
        #   @utils.registerDummyUser()

        KD.remote.api.JUser.isRegistrationEnabled (status)=>
          if status is no
            @registerForm.$('div').hide()
            @registerForm.$('section').show()
            log "Registrations are disabled!!!"
          else
            @registerForm.$('section').hide()
            @registerForm.$('div').show()

      when "home"
        parent.notification?.destroy()
        if @headBannerMsg?
          @headBanner.updatePartial @headBannerMsg
          @headBanner.show()

    @emit "LoginViewAnimated", name

    $('#main-form-handler').removeClass "register recover login reset home lr landed"
    $('#main-form-handler').addClass name

    if KD.config.entryPoint?.slug?
      $('#main-form-handler').addClass 'landed'
