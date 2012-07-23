class LoginView extends KDScrollView

  constructor:->

    super
    @hidden = no
    
    @logo = new KDCustomHTMLView
      tagName     : "div"
      cssClass    : "logo"
      partial     : "Koding"
      click       : => @animateToForm "home"
      # click       : =>
      #   @slideUp ->
      #     appManager.openApplication "Home"
      
    
    @backToHomeLink = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "back-to-home"
      # partial     : "<span></span> Koding Homepage <span></span>"
      # click       : =>
      #   @slideUp ->
      #     appManager.openApplication "Home"

    @backToVideoLink = new KDCustomHTMLView
      tagName     : "a"
      cssClass    : "video-link"
      partial     : "video again."
      click       : => @animateToForm "home"
      # click       : =>
      #   @slideUp ->
      #     appManager.openApplication "Home"


    # @resetFormLink = new KDCustomHTMLView
    #   tagName     : "a"
    #   cssClass    : "reset-link"
    #   partial     : "show reset form"
    #   click       : => @animateToForm "reset"

    @tagLine = new KDCustomHTMLView
      cssClass  : "tagline hidden"
      partial   : "a new way for developers to work."

    @backToLoginLink = new KDCustomHTMLView 
      tagName   : "a"
      # cssClass  : "back-to-login"
      partial   : "Go ahead and login"
      # partial   : "« back to login"
      click     : => @animateToForm "login"

    @goToRequestLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Request an invite"
      # partial     : "Want to get in? Request an invite"
      click       : => @animateToForm "lr"

    @goToRegisterLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Register an account"
      # partial     : "Have an invite? Register an account"
      click       : => @animateToForm "register"

    @bigLinkReg = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Register"
      click       : => @animateToForm "register"

    @bigLinkReq = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Request an Invite"
      click       : => @animateToForm "lr"

    @bigLinkLog = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Login"
      click       : => @animateToForm "login"

    @goToRecoverLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "Recover password."
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

    @launchrock = new KDView
      domId    : "launchrock" 

    @listenTo
      KDEventTypes       : "viewAppended"
      listenedToInstance : @launchrock
      callback           : =>
        @launchrock.setPartial """<div rel="OMJTOEKT" class="lrdiscoverwidget" data-logo="off" data-background="off" data-share-url="koding.com" data-css="#{KD.staticFilesBaseUrl}/css/launchrock.css"></div><script type="text/javascript" src="//launchrock-ignition.s3.amazonaws.com/ignition.1.1.js"></script>"""
    
    @slideShow = new KDView
      cssClass : "slide-show"


    @listenTo
      KDEventTypes       : "viewAppended"
      listenedToInstance : @slideShow
      callback           : =>

        @slideShow.setPartial """<iframe src="//player.vimeo.com/video/45156018?color=ffb500" width="89.13%" height="76.60%" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>"""

        # @slideShow.addSubView new KDButtonView
        #   title    : "."
        #   cssClass : "koding-orange"
        #   click    : => @animateToForm 'lr'

        
        # this is a great video which can live in our codebase
        # <iframe src="http://player.vimeo.com/video/45878034?color=ff9200" width="89.13%" height="75.50%" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>
  
        # iframe = @slideShow.$('iframe')[0]
        # @player = $f(iframe)

        # if window.addEventListener
        #   window.addEventListener 'message', =>
        #     log 'message', arguments
        #   , false
        # else
        #   window.attachEvent 'onmessage', =>
        #     log "onmessage", arguments
        #   , false

        # @player.addEvent 'ready', =>
        #   log "player ready"
        #   @player.addEvent 'pause', => log "player paused"
        #   @player.addEvent 'finish', => log "player finished"
        #   @player.addEvent 'playProgress', => log "player playProgress"
    
        # @slideShow.addSubView new KDCustomHTMLView
        #   tagName  : "a"
        #   cssClass : 'login-register'
        #   partial  : "login/register"
        #   click    : =>
        #     @animateToForm('login')
        

        # @slideShow.setPartial """<div rel="OMJTOEKT" class="lrdiscoverwidget" data-logo="off" data-background="off" data-share-url="koding.com" data-css="http://sinan.koding.com/launchrock.css"></div><script type="text/javascript" src="http://launchrock-ignition.s3.amazonaws.com/ignition.1.1.js"></script>"""
        # @slideShow.addSubView new KDButtonView
        #   title    : "Request an Invite"
        #   cssClass : "koding-blue"
        #   click    : => @animateToForm('login')

  viewAppended:->
    @windowController = @getSingleton("windowController")
    @listenWindowResize()
    @setClass "login-screen home"
    @setTemplate @pistachio()
    @template.update()
    # @hide()

  
  pistachio:->
    """
    <div class="flex-wrapper">
      <div class="login-box-header">
        <a class="betatag">beta</a>
        {{> @logo}}
      </div>
      {{> @loginOptions}}
      {{> @registerOptions}}
      <div class="login-form-holder home">
        {{> @slideShow}}
        {{> @tagLine}}
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
      <div class="launchrock-wrapper">
        <h3 class='kdview kdheaderview '>REQUEST AN INVITE:</h3>
        {{> @launchrock}}
      </div>
    </div>
    <div class="login-footer">
      <p class='bigLink'>{{> @bigLinkReq}}</p>
      <p class='bigLink'>{{> @bigLinkReg}}</p>
      <p class='bigLink'>{{> @bigLinkLog}}</p>
      <p class='reqLink'>Want to get in? {{> @goToRequestLink}}</p>
      <p class='regLink'>Have an invite? {{> @goToRegisterLink}}</p>
      <p class='logLink'>Already a user? {{> @backToLoginLink}}</p>
      <p class='recLink'>Trouble logging in? {{> @goToRecoverLink}}</p>
      <p class='vidLink'>Want to watch the {{> @backToVideoLink}}</p>
    </div>
    <div class="reviews">
      <hr>
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
    {{> @backToHomeLink}}
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
    {winWidth,winHeight} = @windowController
    @$().css marginTop : -winHeight

    @utils.wait 601,()=>
      @hidden = yes
      $('body').removeClass 'login'
      # @hide()
      callback?()
    
  slideDown:(callback)->

    $('body').addClass 'login'
    # @show()
    @$().css marginTop : 0
    @utils.wait 601,()=>
      @hidden = no
      callback?()
  
  _windowDidResize:(event)->

    {winWidth,winHeight} = @windowController
    @$().css marginTop : -winHeight if @hidden
      
  animateToForm: (name)->
    if name is "register"
      bongo.api.JVisitor.isRegistrationEnabled (status)=>
        if status is no
          @registerForm.$('div').hide()
          @registerForm.$('section').show()
          log "Registrations are disabled!!!"
        else
          @registerForm.$('section').hide()
          @registerForm.$('div').show()

    @unsetClass "register recover login reset home lr"
    @setClass name
