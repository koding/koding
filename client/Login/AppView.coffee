class LoginView extends KDView

  stop = KD.utils.stopDOMEvent

  backgroundImageNr = KD.utils.getRandomNumber 15

  backgroundImages  = [

      path         : "1"
      href         : "http://www.flickr.com/photos/charliefoster/"
      photographer : "Charlie Foster"
    ,
      path         : "2"
      href         : "http://pican.de/"
      photographer : "Dietmar Becker"
    ,
      path         : "3"
      href         : "http://www.station75.com/"
      photographer : "Marcin Czerwinski"
    ,
      path         : "4"
      href         : "http://www.station75.com/"
      photographer : "Marcin Czerwinski"
    ,
      path         : "5"
      href         : "http://www.flickr.com/photos/discomethod/sets/72157635620513053/"
      photographer : "Anton Sulsky"
    ,
      path         : "6"
      href         : "http://www.jfrwebdesign.nl/"
      photographer : "Joeri Römer"
    ,
      path         : "7"
      href         : "http://be.net/Zugr"
      photographer : "Zugr"
    ,
      path         : "8"
      href         : ""
      photographer : "Mark Doda"
    ,
      path         : "9"
      href         : "http://www.twitter.com/rickwaalders"
      photographer : "Rick Waalders"
    ,
      path         : "10"
      href         : "http://madebyvadim.com/"
      photographer : "Vadim Sherbakov"
    ,
      path         : "11"
      href         : ""
      photographer : "Zwaddi"
    ,
      path         : "12"
      href         : "http://be.net/Zugr"
      photographer : "Zugr"
    ,
      path         : "13"
      href         : "http://www.romainbriaux.fr/"
      photographer : "Romain Briaux"
    ,
      path         : "14"
      href         : "https://twitter.com/Petchy19"
      photographer : "petradr"
    ,
      path         : "15"
      href         : "http://rileyb.me/"
      photographer : "Riley Briggs"
    ,
      path         : "16"
      href         : "http://chloecolorphotography.tumblr.com/"
      photographer : "Chloe Benko-Prieur"

  ]




  constructor:(options = {}, data)->

    {entryPoint} = KD.config
    options.cssClass = 'hidden'

    super options, data

    @setCss 'background-image', "url('../a/images/unsplash/#{backgroundImageNr}.jpg')"

    @hidden = yes

    handler =(route, event)=>
      stop event
      KD.getSingleton('router').handleRoute route, {entryPoint}

    homeHandler     = handler.bind null, '/'
    loginHandler    = handler.bind null, '/Login'
    registerHandler = handler.bind null, '/Register'
    recoverHandler  = handler.bind null, '/Recover'

    @logo = new KDCustomHTMLView
      cssClass    : "logo"
      partial     : "Koding<cite></cite>"
      click       : homeHandler

    @backToLoginLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Sign In"
      click       : ->
        KD.mixpanel "Login button form in /Login, click"
        loginHandler()

    @goToRecoverLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Forgot your password?"
      testPath    : "landing-recover-password"
      click       : recoverHandler

    @goToRegisterLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Create Account"
      click       : ->
        KD.mixpanel "Register button form in /Login, click"
        registerHandler()

    @github       = new KDButtonView
      style       : 'solid github'
      icon        : yes
      callback    : ->
        KD.mixpanel "Github auth button in /Login, click"
        KD.singletons.oauthController.openPopup "github"

    @github.setPartial "<span class='button-arrow'></span>"

    # @loginOptions = new LoginOptions
    #   cssClass : "login-options-holder log"

    # @registerOptions = new RegisterOptions
    #   cssClass : "login-options-holder reg"

    @loginForm = new LoginInlineForm
      cssClass : "login-form"
      testPath : "login-form"
      callback : (formData)=>
        KD.mixpanel "Login submit, click"
        @doLogin formData

    @registerForm = new RegisterInlineForm
      cssClass : "login-form"
      testPath : "register-form"
      callback : (formData)=>
        KD.mixpanel "Register submit, click"
        @doRegister formData

    @redeemForm = new RedeemInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        KD.mixpanel "Redeem submit, click"
        @doRedeem formData

    @recoverForm = new RecoverInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        KD.mixpanel "Recover password submit, click"
        @doRecover formData

    @resendForm= new ResendEmailConfirmationLinkInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        @resendEmailConfirmationToken formData
        KD.mixpanel "Resend email button, click"

    @resetForm = new ResetInlineForm
      cssClass : "login-form"
      callback : (formData)=>
        @doReset formData

    @finishRegistrationForm = new FinishRegistrationForm
      cssClass  : "login-form foobar"
      callback  : (formData) =>
        @doFinishRegistration formData

    @headBanner = new KDCustomHTMLView
      domId    : "invite-recovery-notification-bar"
      cssClass : "invite-recovery-notification-bar hidden"
      partial  : "..."

    @failureNotice = new KDCustomHTMLView
      cssClass     : "failure-notice hidden"

    KD.getSingleton("mainController").on "landingSidebarClicked", => @unsetClass 'landed'

    setValue = (field, value)=>
      @registerForm[field]?.input?.setValue value
      @registerForm[field]?.placeholder?.setClass 'out'

    mainController = KD.getSingleton "mainController"
    mainController.on "ForeignAuthCompleted", (provider)=>
      isUserLoggedIn = KD.isLoggedIn()
      params = {isUserLoggedIn, provider}

      (KD.getSingleton 'mainController').handleOauthAuth params, (err, resp)=>
        if err
          showError err
          KD.mixpanel "Authenticate with oauth, fail", {provider}
        else
          {account, replacementToken, isNewUser, userInfo} = resp
          if isNewUser
            KD.getSingleton('router').handleRoute '/Register'
            @animateToForm "register"
            for own field, value of userInfo
              setValue field, value

            KD.mixpanel "Github auth register, success"
          else
            if isUserLoggedIn
              mainController.emit "ForeignAuthSuccess.#{provider}"
              KD.mixpanel "Authenticate with oauth, success", {provider}
              new KDNotificationView
                title : "Your #{provider.capitalize()} account has been linked."
                type  : "mini"

            else
              @afterLoginCallback err, {account, replacementToken}
              KD.mixpanel "Github auth login, success"

  viewAppended:->

    @setClass "login-screen login"

    @setTemplate @pistachio()
    @template.update()

    query = KD.utils.parseQuery document.location.search.replace "?", ""

    if query.warning
      suffix  = if query.type is "comment" then "post a comment" else "like an activity"
      message = "You need to be logged in to #{suffix}"

      KD.getSingleton("mainView").createGlobalNotification
        title      : message
        type       : "yellow"
        content    : ""
        closeTimer : 4000
        container  : this

  pistachio:->
      # {{> @loginOptions}}
      # {{> @registerOptions}}
    """
    <div class='tint'></div>
    <div class="flex-wrapper">
      <div class="login-box-header">
        {{> @logo}}
      </div>
      <div class="login-form-holder lf">
        {{> @loginForm}}
      </div>
      <div class="login-form-holder rf">
        {{> @registerForm}}
      </div>
      <div class="login-form-holder frf">
        {{> @finishRegistrationForm}}
      </div>
      <div class="login-form-holder rdf">
        {{> @redeemForm}}
      </div>
      <div class="login-form-holder rcf">
        {{> @recoverForm}}
      </div>
      <div class="login-form-holder rsf">
        {{> @resetForm}}
      </div>
      <div class="login-form-holder resend-confirmation-form">
        {{> @resendForm}}
      </div>
      {{> @failureNotice}}
      <div class="login-footer">
        <div class='first-row clearfix'>
          <div class='fl'>{{> @goToRecoverLink}}</div><div class='fr'>{{> @goToRegisterLink}}<i>•</i>{{> @backToLoginLink}}</div>
        </div>
        {{> @github}}
      </div>
    </div>
    <footer>
      <a href="/tos.html" target="_blank">Terms of service</a><i>•</i><a href="/privacy.html" target="_blank">Privacy policy</a><i>•</i><a href="#{backgroundImages[backgroundImageNr].href}" target="_blank"><span>photo by </span>#{backgroundImages[backgroundImageNr].photographer}</a>
    </footer>
    """

  doReset:({recoveryToken, password})->
    KD.remote.api.JPasswordRecovery.resetPassword recoveryToken, password, (err, username)=>
      if err
        new KDNotificationView
          title : "An error occurred: #{err.message}"
      else
        @resetForm.button.hideLoader()
        @resetForm.reset()
        @headBanner.hide()
        @doLogin {username, password}

  doRecover:(formData)->
    KD.remote.api.JPasswordRecovery.recoverPassword formData['username-or-email'], (err)=>
      @recoverForm.button.hideLoader()
      if err
        new KDNotificationView
          title : "An error occurred: #{err.message}"
      else
        @recoverForm.reset()
        {entryPoint} = KD.config
        KD.getSingleton('router').handleRoute '/Login', {entryPoint}
        new KDNotificationView
          title     : "Check your email"
          content   : "We've sent you a password recovery token."
          duration  : 4500

        KD.mixpanel "Recover password, success"

  resendEmailConfirmationToken:(formData)->
    KD.remote.api.JPasswordRecovery.recoverPassword formData['username-or-email'], (err)=>
      @resendForm.button.hideLoader()
      if err
        new KDNotificationView
          title : "An error occurred: #{err.message}"
      else
        @resendForm.reset()
        {entryPoint} = KD.config
        KD.getSingleton('router').handleRoute '/Login', {entryPoint}
        new KDNotificationView
          title     : "Check your email"
          content   : "We've sent you a confirmation mail."
          duration  : 4500

  doRegister:(formData)->
    (KD.getSingleton 'mainController').isLoggingIn on
    formData.agree = 'on'
    formData.referrer = Cookies.get 'referrer'
    @registerForm.notificationsDisabled = yes
    @registerForm.notification?.destroy()

    # we need to close the group channel so we don't receive the cycleChannel event.
    # getting the cycleChannel even for our own MemberAdded can cause a race condition
    # that'll leak a guest account.
    KD.getSingleton('groupsController').groupChannel?.close()

    KD.remote.api.JUser.convert formData, (err, replacementToken)=>
      account = KD.whoami()
      @registerForm.button.hideLoader()

      if err

        {message} = err
        warn "An error occured while registering:", err
        @registerForm.notificationsDisabled = no
        @registerForm.emit "SubmitFailed", message
      else

        KD.mixpanel.alias account.profile.nickname
        KD.mixpanel "Signup, success"
        _gaq.push ['_trackEvent', 'Sign-up']

        try
          mixpanel.track "Alternate Signup, success"
        catch
          KD.logToExternal "mixpanel doesn't exist"

        Cookies.set 'newRegister', yes
        KD.getSingleton("mainController").swapAccount {account, replacementToken}

        titleText = unless err then 'Good to go, Enjoy!' \
                    else 'Quota exceeded and could not join to the group. Please contact with group admin'
        title = "<span>#{titleText}</span>"

        new KDNotificationView
          cssClass  : "login"
          title     : title
          # content   : 'Successfully registered!'
          duration  : 2000

        return location.reload()  unless KD.remote.isConnected()

        @headBanner.hide()
        #could not joined to the group. Directing to Koding
        window.location.href= "/" if err

        KD.utils.wait 1000, =>
          @registerForm.reset()
          @registerForm.button.hideLoader()
          @hide()
          KD.singleton("router").handleRoute "/Activity"

  doFinishRegistration: (formData) ->
    (KD.getSingleton 'mainController').handleFinishRegistration formData, @bound 'afterLoginCallback'

  doLogin:(credentials)->
    (KD.getSingleton 'mainController').handleLogin credentials, @bound 'afterLoginCallback'

  runExternal = (token)->
    KD.getSingleton("kiteController").run
      kiteName        : "externals"
      method          : "import"
      correlationName : " "
      withArgs        :
        value         : token
        serviceName   : "github"
        userId        : KD.whoami().getId()
      ,
    (err, status)-> console.log "Status of fetching stuff from external: #{status}"


  afterLoginCallback: (err, params={})->
    @loginForm.button.hideLoader()
    {entryPoint} = KD.config
    if err
      showError err
      @loginForm.resetDecoration()
      @$('.flex-wrapper').removeClass 'shake'
      KD.utils.defer => @$('.flex-wrapper').addClass 'animate shake'
    else
      {account} = params
      # check and set preferred BE domain for Koding
      # prevent user from seeing the main wiev
      KD.utils.setPreferredDomain account if account

      mainController = KD.getSingleton('mainController')
      mainView       = mainController.mainViewController.getView()
      mainView.show()
      mainView.$().css "opacity", 1

      firstRoute = KD.getSingleton("router").visitedRoutes.first

      if firstRoute and /^\/(?:Reset|Register|Confirm|R)\//.test firstRoute
        firstRoute = "/Activity"

      @appStorage = KD.getSingleton('appStorageController').storage 'Login', '1.0'
      @appStorage.fetchValue "redirectTo", (redirectTo) =>
        if redirectTo
          firstRoute = "/#{redirectTo}"
          @appStorage.unsetKey "redirectTo", (err) ->
            warn "Failed to reset redirectTo", err  if err

        KD.getSingleton('appManager').quitAll()
        KD.getSingleton('router').handleRoute firstRoute or '/Activity', {replaceState: yes, entryPoint}
        KD.getSingleton('groupsController').on 'GroupChanged', =>
          @headBanner?.hide()
          @loginForm.reset()

        new KDNotificationView
          cssClass  : "login"
          title     : "<span></span>Happy Coding!"
          # content   : "Successfully logged in."
          duration  : 2000
        @loginForm.reset()

        KD.mixpanel "Login, success"
        window.location.reload()  if redirectTo

  doRedeem:({inviteCode})->
    return  unless KD.config.entryPoint?.slug or KD.isLoggedIn()

    KD.remote.cacheable KD.config.entryPoint.slug, (err, [group])=>
      group.redeemInvitation inviteCode, (err)=>
        @redeemForm.button.hideLoader()
        return KD.notify_ err.message or err  if err
        KD.notify_ 'Success!'
        KD.getSingleton('mainController').accountChanged KD.whoami()

        KD.mixpanel "Redeem, success"

  showHeadBanner:(message, callback)->
    $('body').addClass 'recovery'
    @headBannerMsg = message
    @headBanner.updatePartial @headBannerMsg
    @headBanner.unsetClass 'hidden'
    @headBanner.setClass 'show'
    @headBanner.off 'click'
    @headBanner.once 'click', callback
    @headBanner.appendToDomBody()

  headBannerShowInvitation:(invite)->
    @showHeadBanner "Cool! you got an invite! <span>If you already have an account click here to sign in.</span>", =>
      KD.singleton("router").handleRoute "/Login"
      @headBanner.hide()

    KD.getSingleton('router').clear @getRouteWithEntryPoint 'Register'
    $('body').removeClass 'recovery'
    @show =>
      @animateToForm "register"
      @$('.flex-wrapper').addClass 'taller'
      KD.getSingleton('mainController').emit 'InvitationReceived', invite

  hide:(callback)->

    @$('.flex-wrapper').removeClass 'expanded'
    @emit "LoginViewHidden"
    @setClass 'hidden'
    callback?()

  show:(callback)->

    @unsetClass 'hidden'
    @emit "LoginViewShown"
    @hidden = no
    callback?()

  # click:(event)->
  #   if $(event.target).is('.login-screen')
  #     @hide ->
  #       router = KD.getSingleton('router')
  #       routed = no
  #       for route in router.visitedRoutes by -1
  #         {entryPoint} = KD.config
  #         routeWithoutEntryPoint =
  #           if entryPoint?.type is 'group' and entryPoint.slug
  #           then route.replace "/#{entryPoint.slug}", ''
  #           else route
  #         unless routeWithoutEntryPoint in ['/Login', '/Register', '/Recover', '/ResendToken']
  #           router.handleRoute route
  #           routed = yes
  #           break
  #       router.clear()  unless routed

  setCustomDataToForm: (type, data)->
    formName = "#{type}Form"
    @[formName].addCustomData data
    # @resetForm.addCustomData {recoveryToken}

  animateToForm: (name)->

    @show =>
      switch name
        when "register"
          # @utils.wait 5000, =>
          #   @utils.registerDummyUser()

          KD.remote.api.JUser.isRegistrationEnabled (status)=>
            if status is no
              log "Registrations are disabled!!!"
              @setFailureNotice
                cssClass  : "registrations-disabled"
                title     : "REGISTRATIONS ARE CURRENTLY DISABLED"
                message   : "We're sorry for that, please follow us on <a href='http://twitter.com/koding' target='_blank'>twitter</a>
                  if you want to be notified when registrations are enabled again."
              @github.hide()
              @$(".login-footer").addClass 'hidden'
              @animateToForm "failureNotice"
            else
              @github.show()
              @$(".login-footer").removeClass 'hidden'

          KD.mixpanel "Register form, click"

        when "home"
          parent.notification?.destroy()
          if @headBannerMsg?
            @headBanner.updatePartial @headBannerMsg
            @headBanner.show()

      @unsetClass "register recover login reset home resendEmail finishRegistration"
      @emit "LoginViewAnimated", name
      @setClass name
      @$('.flex-wrapper').removeClass 'three one'

      switch name
        when "register"
          @github.setTitle "Sign up with GitHub"
          @registerForm.email.input.setFocus()
        when "finishRegistration"
          @finishRegistrationForm.username.input.setFocus()
        when "redeem"
          @$('.flex-wrapper').addClass 'one'
          @redeemForm.inviteCode.input.setFocus()
        when "login"
          @github.setTitle "Sign in with GitHub"
          @loginForm.username.input.setFocus()
        when "recover"
          @$('.flex-wrapper').addClass 'one'
          @github.hide()
          @recoverForm.usernameOrEmail.input.setFocus()
        when "resendEmail"
          @$('.flex-wrapper').addClass 'one'
          @resendForm.usernameOrEmail.input.setFocus()
        when "failureNotice"
          @$('.flex-wrapper').addClass 'one'
          @github.hide()
          @$(".login-footer").addClass 'hidden'
          @failureNotice.show()
        when "reset"
          @github.hide()

  getRouteWithEntryPoint:(route)->
    {entryPoint} = KD.config
    if entryPoint and entryPoint.slug isnt KD.defaultSlug
      return "/#{entryPoint.slug}/#{route}"
    else
      return "/#{route}"

  showError = (err)->
    if err.code and err.code is 403
      {name, nickname}  = err.data
      KD.getSingleton('appManager').tell 'Account', 'displayConfirmEmailModal', name, nickname

    else if err.message.length > 50
      new KDModalView
        title        : "Something is wrong!"
        width        : 500
        overlay      : yes
        cssClass     : "new-kdmodal"
        content      : "<div class='modalformline'>" + err.message + "</div>"
    else
      new KDNotificationView
        title   : err.message
        duration: 1000

  setFailureNotice: ({cssClass, title, message}) ->
    @failureNotice.setClass cssClass  if cssClass
    @failureNotice.updatePartial \
      """
      <strong>#{title}</strong>
      <p>#{message}</p>
      """
