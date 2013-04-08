class LoginView extends KDScrollView

  stop = (event)->
    event.preventDefault()
    event.stopPropagation()

  constructor:(options = {}, data)->

    entryPoint = ''
    if KD.config.profileEntryPoint? or KD.config.groupEntryPoint?
      options = cssClass : 'land-page'
      entryPoint = KD.config.profileEntryPoint or KD.config.groupEntryPoint
    else
      if KD.isLoggedIn() then options = cssClass : 'hidden'

    super options, data

    handler =(route, event)=>
      route = "/#{entryPoint}#{route}" if entryPoint
      stop event
      @getSingleton('router').handleRoute route

    homeHandler       = handler.bind null, '/'
    learnMoreHandler  = handler.bind null, '/Join'
    loginHandler      = handler.bind null, '/Login'
    registerHandler   = handler.bind null, '/Register'
    joinHandler       = handler.bind null, '/Join'
    recoverHandler    = handler.bind null, '/Recover'

    @logo = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "logo"
      partial     : "Koding"
      click       : handler.bind null, '/'

    @backToLoginLink = new KDCustomHTMLView
      tagName   : "a"
      partial   : "Go ahead and login"
      click     : loginHandler

    @goToRecoverLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Recover password"
      click       : recoverHandler

    @loginOptions = new LoginOptions
      cssClass : "login-options-holder log"

    @registerOptions = new RegisterOptions
      cssClass : "login-options-holder reg"

    @loginForm = new LoginInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        formData.clientId = $.cookie('clientId')
        @doLogin formData

    @registerForm = new RegisterInlineForm
      cssClass : "login-form"
      callback : (formData)=> @doRegister formData

    @recoverForm = new RecoverInlineForm
      cssClass : "login-form"
      callback : (formData)=> @doRecover formData

    @resetForm = new ResetInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        formData.clientId = $.cookie('clientId')
        @doReset formData

    @requestForm = new RequestInlineForm
      cssClass : "login-form"
      callback : (formData)=> @doRequest formData

    @headBanner = new KDCustomHTMLView
      cssClass : "head-banner hidden"
      partial  : "..."

    @getSingleton("mainController").on "landingSidebarClicked", => @unsetClass 'landed'

  viewAppended:->

    @listenWindowResize()
    @setClass "login-screen home"

    @setTemplate @pistachio()
    @template.update()
    # @hide()

  pistachio:->
    """
    {{> @headBanner}}
    <div class="flex-wrapper">
      <div class="login-box-header">
        <a class="betatag">beta</a>
        {{> @logo}}
      </div>
      {{> @loginOptions}}
      {{> @registerOptions}}
      <div class="login-form-holder lf">
        {{> @loginForm}}
      </div>
      <div class="login-form-holder rf">
        {{> @registerForm}}
      </div>
      <div class="login-form-holder rcf">
        {{> @recoverForm}}
      </div>
      <div class="login-form-holder rsf">
        {{> @resetForm}}
      </div>
      <div class="login-form-holder rqf">
        <h3 class="kdview kdheaderview "><span>REQUEST AN INVITE:</span></h3>
        {{> @requestForm}}
      </div>
    </div>
    <div class="login-footer">
      <p class='logLink'>Already a user? {{> @backToLoginLink}}</p>
      <p class='recLink'>Trouble logging in? {{> @goToRecoverLink}}</p>
    </div>
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
        mainController = @getSingleton('mainController')
        mainView       = mainController.mainViewController.getView()
        mainController.accountChanged account
        mainView.show()
        mainView.$().css "opacity", 1

        {groupEntryPoint} = KD.config


        if groupEntryPoint and groupEntryPoint isnt 'koding'
          route = "/#{groupEntryPoint}/Activity"
        else
          route = "/Activity"

        @getSingleton('router').handleRoute route, replaceState: yes

        new KDNotificationView
          cssClass  : "login"
          title     : "<span></span>Happy Coding!"
          # content   : "Successfully logged in."
          duration  : 2000
        @loginForm.reset()

        @hideView()

        if KD.config.profileEntryPoint? or KD.config.groupEntryPoint?
          @getSingleton('lazyDomController').hideLandingPage()

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
    @$('.login-footer').hide()
    @$('.footer-links').hide()
    $('body').addClass 'recovery'

    @headBannerMsg = message
    @headBanner.updatePartial @headBannerMsg
    @headBanner.unsetClass 'hidden'
    @headBanner.setClass 'show'
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

  headBannerShowInvitation:(invite)->

    @showHeadBanner "Cool! you got an invite! <span>Click here to register your account.</span>", =>
      @headBanner.hide()
      @getSingleton('router').clear '/Register'
      $('body').removeClass 'recovery'
      @showView =>
        @animateToForm "register"
        @getSingleton('mainController').emit 'InvitationReceived', invite

  hideView:(callback)->

    @unsetClass 'landed'

    @utils.wait 601, =>
      @emit "LoginViewHidden"
      @hidden = yes
      @hide()
      callback?()

  showView:(callback)->

    @show()
    @emit "LoginViewShown"

    @utils.wait 601,()=>
      @hidden = no
      callback?()

  click:(event)->
    @emit 'LoginViewWasClicked' if $(event.target).is('.login-screen')

  animateToForm: (name)->

    log 'animateForm called.', arguments

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

    @unsetClass "register recover login reset home lr landed"
    @emit "LoginViewAnimated", name
    @setClass name

    if KD.config.profileEntryPoint? or KD.config.groupEntryPoint?
      @setClass 'landed' unless name is 'home'
