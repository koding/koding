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
      callback : (formElements)=> @doLogin formElements

    @registerForm = new RegisterInlineForm
      cssClass : "login-form"
      callback : (formElements)=> @doRegister formElements

    @recoverForm = new RecoverInlineForm
      cssClass : "login-form"
      callback : (formElements)=> @doRecover formElements

    @resetForm = new ResetInlineForm
      cssClass : "login-form"
      callback : (formElements)=> @doReset formElements

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

  doRecover:(formElements)->
    bongo.api.JPasswordRecovery.recoverPassword formElements['username-or-email'], (err)=>
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

  doRegister:(formElements)->
    formElements.agree = 'on'
    bongo.api.JUser.register formElements, (error, result)=>
      @registerForm.button.hideLoader()
      if error
        new KDNotificationView
          title   : 'Error' + error
          duration: 3000
      else
        new KDNotificationView
          title   : 'Good to go!'
          duration: 1000
        setTimeout =>
          @animateToForm "login"
          @registerForm.reset()
          @registerForm.button.hideLoader()
        , 1000

  doLogin:(credentials)->
    bongo.api.JUser.login credentials, (error, result) =>
      @loginForm.button.hideLoader()
      if error
        new KDNotificationView
          title   : error.message
          duration: 1000
      else
        new KDNotificationView
          title   : "Successfully logged in!"
          duration: 1000
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

class LoginViewInlineForm extends KDFormView

  viewAppended:()->
    @setTemplate @pistachio()
    @template.update()

    @listenTo 
      KDEventTypes       : "ValidationFailed"
      listenedToInstance : @
      callback           : =>
        @button.hideLoader()


  pistachio:->


class LoginInlineForm extends LoginViewInlineForm
  constructor:->
    super
    @username = new KDInputView
      name  : "username"
      placeholder : "Enter Koding Username"
      validate  :
        rules     :
          required  : yes
        messages  :
          required  : "Please enter a username."

    @password = new KDInputView
      name  : "password"
      type  : "password"
      placeholder : "Enter Koding Password"
      validate  :
        rules     :
          required  : yes
        messages  :
          required  : "Please enter your password."

    @button = new KDButtonView
      title       : "SIGN IN"
      style       : "koding-orange"
      type        : 'submit'
      loader      :
        color     : "#ffffff"
        diameter  : 21

  pistachio:->
    """
    <div>{{> @username}}</div>
    <div>{{> @password}}</div>
    <div>{{> @button}}</div>
    """

class RegisterInlineForm extends LoginViewInlineForm
  constructor:->
    super
    @firstName = new KDInputView
      cssClass      : "half-size"
      name          : "firstName"
      placeholder   : "Your first name"
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Please enter your first name."

    @lastName = new KDInputView
      cssClass      : "half-size"
      name          : "lastName"
      placeholder   : "Your last name"
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Please enter your last name."

    @email = new KDInputView
      name          : "email"
      placeholder   : "Your email address"
      validate      :
        event       : "blur"
        rules       :
          required  : yes
          email     : yes
        messages    :
          required  : "Please enter your email address."
          email     : "That doesn't seem like a valid email address."

    @username = new KDInputView
      name                : "username"
      forceCase           : "lowercase"
      placeholder         : "Desired username"
      validate            :
        event             : 'blur'
        rules             :
          required        : yes
          rangeLength     : [4,25]
          userProvidedFn  : (input, event)->
            val = $.trim input.inputGetValue()
            return if /\s/.test val then no else yes
        messages          :
          required        : "Please enter a username."
          userProvidedFn  : "For username only lowercase letters and numbers are allowed!"
          rangeLength     : "Username should be minimum 4 maximum 25 chars!"
      tooltip             :
        placement         : "right"
        offset            : 2
        title             : """
                             Only lowercase letters and numbers are allowed, 
                             max 25 characters. Also keep in mind that the username you select will 
                             be a part of your kodingen domain, and can't be changed later. 
                             i.e. http://username.kodingen.com <h1></h1>
                            """



    @password = new KDInputView
      name          : "password"
      type          : "password"
      placeholder   : "Create a password"
      validate      :
        rules       :
          required  : yes
          minLength : 8
        messages    :
          required  : "Please enter a password."
          minLength : "Passwords should be at least 8 characters."

    @passwordConfirm = new KDInputView
      name          : "passwordConfirm"
      type          : "password"
      placeholder   : "Confirm your password"
      validate      :
        rules       :
          required  : yes
          match     : @password
        messages    :
          required  : "Please confirm your password."
          match     : "Password confirmation doesn't match!"

    @button = new KDButtonView
      title         : "REGISTER"
      type          : 'submit'
      style         : "koding-orange"
      loader        :
        color       : "#ffffff"
        diameter    : 21
    
    @invitationCode = new KDInputView
      cssClass      : "half-size"
      name          : "inviteCode"
      forceCase     : "lowercase"
      placeholder   : "your code..."
      # defaultValue  : "futureinsights"
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Please enter your invitation code."

  viewAppended:()->
    super
    KD.getSingleton('mainController').registerListener
      KDEventTypes  : 'InvitationReceived'
      listener      : @
      callback      : (pubInst, invite)=>
        @$('.invitation-field').addClass('hidden')
        @$('.invited-by').removeClass('hidden')
        {origin} = invite
        @invitationCode.inputSetValue invite.code
        @email.inputSetValue invite.inviteeEmail
        if origin instanceof bongo.api.JAccount
          @addSubView new AvatarStaticView({size: width : 30, height : 30}, origin), '.invited-by .wrapper'
          @addSubView new ProfileTextView({}, origin), '.invited-by .wrapper'
        else
          @$('.invited-by').addClass('hidden')

  pistachio:->
    """
    <div>{{> @firstName}}{{> @lastName}}</div>
    <div>{{> @email}}</div>
    <div>{{> @username}}</div>
    <div>{{> @password}}</div>
    <div>{{> @passwordConfirm}}</div>
    <div class='invitation-field invited-by hidden'>
      <span class='icon'></span>
      Invited by:
      <span class='wrapper'></span>
    </div>
    <div class='invitation-field clearfix'>
      <span class='icon'></span>
      Invitation code:
      {{> @invitationCode}}
    </div>
    <div>{{> @button}}</div>
    """

class RecoverInlineForm extends LoginViewInlineForm
  constructor:->
    super
    @usernameOrEmail = new KDInputView
      name          : "username-or-email"
      placeholder   : "Enter username or email"
      validate      :
        rules       :
          required  : yes
        messages    :
          required  : "Please enter your username or email."

    @button = new KDButtonView
      title       : "RECOVER PASSWORD"
      style       : "koding-orange"
      type        : 'submit'
      loader      :
        color     : "#ffffff"
        diameter  : 21
    
  pistachio:->
    """
    <div>{{> @usernameOrEmail}}</div>
    <div>{{> @button}}</div>
    """

class ResetInlineForm extends LoginViewInlineForm
  constructor:->
    super
    @password = new KDInputView
      name          : "password"
      type          : "password"
      placeholder   : "Enter a new password"
      validate      :
        rules       :
          required  : yes
          minLength : 8
        messages    :
          required  : "Please enter a password."
          minLength : "Passwords should be at least 8 characters."

    @passwordConfirm = new KDInputView
      name          : "passwordConfirm"
      type          : "password"
      placeholder   : "Confirm your password"
      validate      :
        rules       :
          required  : yes
          match     : @password
        messages    :
          required  : "Please confirm your password."
          match     : "Password confirmation doesn't match!"

    @button = new KDButtonView
      title : "RESET PASSWORD"
      style : "koding-orange"
      type  : 'submit'
      loader      :
        color     : "#ffffff"
        diameter  : 21

  pistachio:->
    """
    <div class='login-hint'>Set your new password below.</div>
    <div>{{> @password}}</div>
    <div>{{> @passwordConfirm}}</div>
    <div>{{> @button}}</div>
    """

class LoginOptions extends KDView
  viewAppended:->
    @addSubView new KDHeaderView
      type      : "small"
      title     : "SIGN IN WITH:"
    
    @addSubView optionsHolder = new KDCustomHTMLView 
      tagName   : "ul"
      cssClass  : "login-options"

    optionsHolder.addSubView new KDCustomHTMLView 
      tagName   : "li"
      cssClass  : "koding active"
      partial   : "koding"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with Koding</p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName   : "li"
      cssClass  : "github"
      partial   : "github"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with GitHub <cite>coming soon...</cite></p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName   : "li"
      cssClass  : "facebook"
      partial   : "facebook"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with Facebook <cite>coming soon...</cite></p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName   : "li"
      cssClass  : "google"
      partial   : "google"
      tooltip   :
        title   : "<p class='login-tip'>Sign in with Google <cite>coming soon...</cite></p>"

class RegisterOptions extends KDView
  viewAppended:->
    @addSubView new KDHeaderView
      type     : "small"
      title    : "REGISTER WITH:"
    
    @addSubView optionsHolder = new KDCustomHTMLView 
      tagName  : "ul"
      cssClass : "login-options"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName  : "li"
      cssClass : "koding active"
      partial  : "koding"
      tooltip  :
        title  : "<p class='login-tip'>Register with Koding</p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName  : "li"
      cssClass : "github"
      partial  : "github"
      tooltip  :
        title  : "<p class='login-tip'>Register with GitHub <cite>coming soon...</cite></p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName  : "li"
      cssClass : "facebook"
      partial  : "facebook"
      tooltip  :
        title  : "<p class='login-tip'>Register with Facebook <cite>coming soon...</cite></p>"

    optionsHolder.addSubView new KDCustomHTMLView
      tagName  : "li"
      cssClass : "google"
      partial  : "google"
      tooltip  :
        title  : "<p class='login-tip'>Register with Google <cite>coming soon...</cite></p>"


# old LOGIN PAGE, still active though
# class PageLogin extends KDView
# 
#   KD.registerPage "Login",PageLogin
# 
#   formSubmit:(credentials)=>
#     # windowController.destroyAllLocalStorages()
#     bongo.api.JUser.login credentials, (error, result) =>
#       if error
#         new KDNotificationView
#           title   : error.message
#           duration: 1000
#       else
#         @handleEvent type: 'NavigationLinkTitleClick', pageName:'Home', appPath:"Activity"
#         new KDNotificationView
#           title   : "Successfully logged in!"
#           duration: 1000
#     # bongo.api.Site.login credentials,(result)=>
#     #   log "login response :",result
#     #   if result.success
#     #     new KDNotificationView
#     #       title   : "Successfully logged in!"
#     #       duration: 1000
#     #     @getSingleton("site").refreshAccount()
#     #   else
#     #     new KDNotificationView
#     #       title   : result.error.message
#     #       content : result.error.stack
#     #       duration: 5000
#     #       overlay : yes
# 
#   viewAppended:()->
# 
#     @addSubView header = new HeaderViewSection type : "big", title : "Login"
# 
#     form      = new KDFormView
#       callback :  @formSubmit
# 
#     fieldset1 = new KDCustomHTMLView "fieldset"
#     fieldset2 = new KDCustomHTMLView "fieldset"
#     fieldset3 = new KDCustomHTMLView "fieldset"
#     fieldset4 = new KDCustomHTMLView "fieldset"
#       cssClass : "inner-split-pane"
# 
#     labelUsername = new KDLabelView
#       title : "Username:"
#     labelPassword = new KDLabelView
#       title : "Password:"
#     labelRemember = new KDLabelView
#       title : "Remember me:"
#     inputUsername = new KDInputView
#       label : labelUsername
#       name  : "username"
#     inputPassword = new KDInputView
#       label : labelPassword
#       name  : "password"
#       type  : "password"
#     inputRemember = new KDInputView
#       type  : "checkbox"
#       label : labelRemember
#       name  : "remember"
#     buttonLogin = new KDButtonView
#       title       : "Login"
#       callback: =>
#         yes
#     registerButton = new KDButtonView
#       title : "Register"
#       type  : 'submit'
#       callback: =>
#         @handleEvent {type:"NavigationTrigger", pageName: 'Register', appPath:"Register"}
#         no
#     fieldset1.addSubView labelUsername
#     fieldset1.addSubView inputUsername
#     form.addSubView fieldset1
#     fieldset2.addSubView labelPassword
#     fieldset2.addSubView inputPassword
#     form.addSubView fieldset2
#     fieldset3.addSubView labelRemember
#     fieldset3.addSubView inputRemember
#     form.addSubView fieldset3
#     form.addSubView buttonLogin
#     form.addSubView registerButton
#     inputUsername.inputSetFocus()
#     for provider in ['facebook', 'twitter', 'google', 'github', 'dropbox']
#       f = (provider)=>
#         fieldset4.addSubView new KDButtonView
#           domId : "id-signup-with-#{provider}"
#           title : "Sign Up with #{provider.capitalize()}"
#           icon  : yes
#           callback:()=>
#             @getSingleton("site").popupWindowOAuth "/auth/#{provider}"
#             no
#       f provider
#     form.addSubView fieldset4
#     @addSubView form
