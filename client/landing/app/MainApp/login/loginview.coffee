class LoginView extends KDScrollView

  stop =(event)->
    event.preventDefault()
    event.stopPropagation()

  constructor:->

    super
    @hidden = no

    handler =(route, event)=>
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
      click       : homeHandler
      # @animateToForm "home"
      # click       : =>
      #   @slideUp ->
      #     appManager.openApplication "Home"


    @backToHomeLink = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "back-to-home"
      click       : homeHandler
      # partial     : "<span></span> Koding Homepage <span></span>"
      # click       : =>
      #   @slideUp ->
      #     appManager.openApplication "Home"

    @backToVideoLink = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "video-link"
      partial     : "video again?"
      click       : homeHandler
      # click       : =>
      #   @slideUp ->
      #     appManager.openApplication "Home"

    @backToLoginLink = new KDCustomHTMLView
      tagName   : "a"
      # cssClass  : "back-to-login"
      partial   : "Go ahead and login"
      # partial   : "« back to login"
      click     : loginHandler
        # @animateToForm "login"

    @goToRequestLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Request an invite"
      # partial     : "Want to get in? Request an invite"
      click       : joinHandler
        # @animateToForm "lr"

    @goToRegisterLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Register an account"
      # partial     : "Have an invite? Register an account"
      click       : registerHandler

    @bigLinkReg = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Register"
      click       : registerHandler

    @bigLinkReg1 = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Register"
      click       : registerHandler

    @bigLinkReq = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Request an Invite"
      click       : joinHandler

    @bigLinkReq1 = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Request an Invite"
      click       : joinHandler

    @bigLinkLog = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Login"
      click       : loginHandler

    @bigLinkLog1 = new KDCustomHTMLView
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

    @video = new KDView
      cssClass : "video-wrapper"

    @on "LoginViewHidden", (name)=>
      @video.updatePartial ""

    @on "LoginViewShown", (name)=>
      if @video.$('iframe').length is 0
        @video.setPartial """<iframe src="//player.vimeo.com/video/45156018?color=ffb500" width="89.13%" height="76.60%" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>"""

    @video.on "viewAppended", =>
      unless KD.isLoggedIn()
        @video.setPartial """<iframe src="//player.vimeo.com/video/45156018?color=ffb500" width="89.13%" height="76.60%" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>"""
      else
        @animateToForm 'login'

    @slideShow = new HomeSlideShowHolder

  viewAppended:->
    @windowController = @getSingleton("windowController")
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
      <div class="login-form-holder home">
        {{> @video}}
      </div>
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
      <p class='bigLink'>{{> @bigLinkReq}}</p>
      <p class='bigLink'>{{> @bigLinkReg}}</p>
      <p class='bigLink'>{{> @bigLinkLog}}</p>
      <p class='bigLink'>{{> @bigLinkLearn}}</p>
      <p class='reqLink'>Want to get in? {{> @goToRequestLink}}</p>
      <p class='regLink'>Have an invite? {{> @goToRegisterLink}}</p>
      <p class='logLink'>Already a user? {{> @backToLoginLink}}</p>
      <p class='recLink'>Trouble logging in? {{> @goToRecoverLink}}</p>
      <p class='vidLink'>Want to watch the {{> @backToVideoLink}}</p>
    </div>
    <section>
      <hr id='home-reviews'>
      <div class="reviews">
        <p>A new way for developers to work</p>
        <span>We said.</span>
        <p>Wow! Cool - good luck!</p>
        <span>Someone we talked to the other day...</span>
        <p>I don't get it... What is it, again?</p>
        <span>Same dude.</span>
        <p>Real software development in the browser...</p>
        <span>Us again.</span>
        <p>with a real VM and a real Terminal?</p>
        <span>"and for free? You got to be kidding me..." he added. We gave him a beta invite.</span>
      </div>
      <hr id='home-screenshots'>
      <div class="screenshots">
        {{> @slideShow}}
      </div>
      <hr/>
      <div class="footer-links">
        <p class='bigLink'>{{> @bigLinkReq1}}</p>
        <p class='bigLink'>{{> @bigLinkReg1}}</p>
        <p class='bigLink'>{{> @bigLinkLog1}}</p>
      </div>
      <footer class='copy'>&copy;#{(new Date).getFullYear()} All rights reserved Koding, Inc.</footer>
    </section>
    {{> @backToHomeLink}}
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
    KD.remote.api.JUser.register formData, (error, account, replacementToken)=>
      log arguments
      @registerForm.button.hideLoader()
      if error
        {message} = error
        @registerForm.emit "SubmitFailed", message
      else
        $.cookie 'clientId', replacementToken
        @getSingleton('mainController').accountChanged account
        new KDNotificationView
          cssClass  : "login"
          title     : if kodingenUser then '<span></span>Nice to see an old friend here!' else '<span></span>Good to go, Enjoy!'
          # content   : 'Successfully registered!'
          duration  : 2000
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
    @$('.login-footer').hide()
    @$('.footer-links').hide()
    @headBannerMsg = message
    @headBanner.updatePartial @headBannerMsg
    @headBanner.unsetClass 'hidden'
    @headBanner.setClass 'show'
    $('body').addClass 'recovery'
    @headBanner.click = callback

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
      @slideDown =>
        @animateToForm "register"
        @getSingleton('mainController').emit 'InvitationReceived', invite

  slideUp:(callback)->
    {winWidth,winHeight} = @windowController
    @$().css marginTop : -winHeight
    @utils.wait 601,()=>
      @emit "LoginViewHidden"
      @hidden = yes
      $('body').removeClass 'login'
      # @hide()
      callback?()

  slideDown:(callback)->

    $('body').addClass 'login'
    # @show()
    @emit "LoginViewShown"
    @$().css marginTop : 0
    @utils.wait 601,()=>
      @hidden = no
      callback?()

  _windowDidResize:(event)->

    {winWidth,winHeight} = @windowController
    @$().css marginTop : -winHeight if @hidden

  animateToForm: (name)->
    switch name
      when "register"
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

    @unsetClass "register recover login reset home lr"
    @emit "LoginViewAnimated", name
    @setClass name
