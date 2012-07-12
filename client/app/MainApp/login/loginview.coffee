class LoginView extends KDScrollView

  constructor:->

    super
    @hidden = yes
    
    @logo = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "logo"
      partial     : "Koding"
      click       : =>
        @slideUp ->
          appManager.openApplication "Home"
      
    
    @backToHomeLink = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "back-to-home"
      partial     : "<span></span> Koding Homepage <span></span>"
      attributes  :
        href      : "#"
      click       : =>
        @slideUp ->
          appManager.openApplication "Home"

    @resetFormLink = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "reset-link hidden"
      partial     : "show reset form"
      attributes  :
        href      : "#"
      click       : => @animateToForm "reset"

    @backToLoginLink = new KDCustomHTMLView 
      tagName   : "a"
      cssClass  : "back-to-login"
      partial   : "« back to login"
      attributes:
        href    : "#"
      click     : => @animateToForm "login"

    @goToRegisterLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Register a new account."
      attributes  :
        href      : "#"
      click       : => @animateToForm "register"

    @goToRecoverLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Forgot password?"
      attributes  :
        href      : "#"
      click       : => @animateToForm "recover"

    @loginOptions = new LoginOptions
      cssClass : "login-options-holder log"

    @registerOptions = new RegisterOptions
      cssClass : "login-options-holder reg"

    @loginForm = new LoginInlineForm
      cssClass : "login-form"
      callback : (formData)=> @doLogin formData

    @registerForm = new RegisterInlineForm
      cssClass : "login-form"
      callback : (formData)=> @doRegister formData

    @recoverForm = new RecoverInlineForm
      cssClass : "login-form"
      callback : (formData)=> @doRecover formData

    @resetForm = new ResetInlineForm
      cssClass : "login-form"
      callback : (formData)=> @doReset formData

  viewAppended:->
    @windowController = @getSingleton("windowController")
    @listenWindowResize()
    @setClass "login-screen login"
    @setTemplate @pistachio()
    @template.update()
    @hide()
  
  
  pistachio:->
    """
    <div class="flex-wrapper">
      <div class="login-box-header">
        <a class="betatag">beta</a>
        {{> @logo}}
        {{> @backToLoginLink}}
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
    </div>
    <div class="login-footer">
      <p class='regLink'>Haven't signed up yet? {{> @goToRegisterLink}}</p>
      <p class='recLink'>Trouble logging in? {{> @goToRecoverLink}}</p>
    </div>
    {{> @backToHomeLink}}
    {{> @resetFormLink}}
    """    

  doReset:({recoveryToken, password})->
    bongo.api.JPasswordRecovery.resetPassword recoveryToken, password, (err, username)=>
      @resetForm.button.hideLoader()
      @resetForm.reset()
      @animateToForm 'login'
      @doLogin {username, password}

  doRecover:(formData)->
    bongo.api.JPasswordRecovery.recoverPassword formData['username-or-email'], (err)=>
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
    bongo.api.JUser.register formData, (error, result)=>
      @registerForm.button.hideLoader()
      if error
        {message} = error
        @registerForm.emit "SubmitFailed", message
      else
        new KDNotificationView
          cssClass  : "login"
          title     : if kodingenUser then '<span></span>Nice to see an old friend here!' else '<span></span>Good to go, Enjoy!'
          # content   : 'Successfully registered!'
          duration  : 2000
        setTimeout =>
          @animateToForm "login"
          @registerForm.reset()
          @registerForm.button.hideLoader()
        , 1000

  doLogin:(credentials)->
    credentials.username = credentials.username.toLowerCase()
    bongo.api.JUser.login credentials, (error, result) =>
      @loginForm.button.hideLoader()
      if error
        new KDNotificationView
          title   : error.message
          duration: 1000
      else
        new KDNotificationView
          cssClass  : "login"
          title     : "<span></span>Happy Coding!"
          # content   : "Successfully logged in."
          duration  : 2000
        @loginForm.reset()

  
  slideUp:(callback)->
    # {winWidth,winHeight} = @windowController
    @$().animate marginTop : -@getHeight(),600,()=>
      @hidden = yes
      $('body').removeClass 'login'
      @hide()
      callback?()
    
  slideDown:(callback)->
    $('body').addClass 'login'
    @show()
    @$().animate marginTop : 0,600,()=>
      @hidden = no
      callback?()
  
  _windowDidResize:(event)->
    {winWidth,winHeight} = @windowController
    options = {}
    if @hidden
      options.marginTop = -winHeight
    @$().css options
      
  animateToForm: (name)->
    @unsetClass "register recover login reset"
    @setClass name
