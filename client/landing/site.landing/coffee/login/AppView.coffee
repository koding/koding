JView                                 = require './../core/jview'
CustomLinkView                        = require './../core/customlinkview'
LoginInputView                        = require './logininputview'
LoginInlineForm                       = require './loginform'
RegisterInlineForm                    = require './registerform'
RedeemInlineForm                      = require './redeemform'
RecoverInlineForm                     = require './recoverform'
ResetInlineForm                       = require './resetform'
ResendEmailConfirmationLinkInlineForm = require './resendmailconfirmationform'
LoginOptions                          = require './loginoptions'
RegisterOptions                       = require './registeroptions'
MainControllerLoggedOut               = require './../core/maincontrollerloggedout'
{ getGroupNameFromLocation }          = KD.utils


module.exports = class LoginView extends JView

  RECAPTCHA_JS = 'https://www.google.com/recaptcha/api.js?onload=onRecaptchaloadCallback&render=explicit'

  stop           = KD.utils.stopDOMEvent
  ENTER          = 13
  USERNAME_VALID = no

  pendingSignupRequest = no

  backgroundImages  = [
    [ 'Charlie Foster', 'http://www.flickr.com/photos/charliefoster/' ]
    [ 'Dietmar Becker', 'http://pican.de/' ]
    [ 'Marcin Czerwinski', 'http://www.station75.com/' ]
    [ 'Marcin Czerwinski', 'http://www.station75.com/' ]
    [ 'Anton Sulsky', 'http://www.flickr.com/photos/discomethod/sets/72157635620513053/' ]
    [ 'Joeri Römer', 'http://www.jfrwebdesign.nl/' ]
    [ 'Zugr', 'http://be.net/Zugr' ]
    [ 'Mark Doda', '' ]
    [ 'Rick Waalders', 'http://www.twitter.com/rickwaalders' ]
    [ 'Vadim Sherbakov', 'http://madebyvadim.com/' ]
    [ 'Zwaddi', '' ]
    [ 'Zugr', 'http://be.net/Zugr' ]
    [ 'Romain Briaux', 'http://www.romainbriaux.fr/' ]
    [ 'petradr', 'https://twitter.com/Petchy19' ]
    [ 'Riley Briggs', 'http://rileyb.me/' ]
    [ 'Chloe Benko-Prieur', 'http://chloecolorphotography.tumblr.com/' ]
  ]

  backgroundImageNr = MainControllerLoggedOut.loginImageIndex

  do ->
    image      = new Image
    bgImageUrl = "/a/site.landing/images/unsplash/#{backgroundImageNr}.jpg"
    image.src  = bgImageUrl

    image.classList.add 'off-screen-login-image'

    document.head.appendChild (new KDCustomHTMLView {
      tagName    : 'style'
      partial    : ".kdview.login-screen:after { background-image : url('#{bgImageUrl}')}"
    }).getElement()


  constructor:(options = {}, data)->

    options.cssClass   = 'login-screen login'
    options.attributes =
      testpath         : 'login-container'

    super options, data

    @logo = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'koding-logo'
      partial    : '<cite></cite>'
      attributes : href : '/'

    @backToLoginLink = new CustomLinkView
      title       : 'Sign In'
      href        : '/Login'
      click       : ->

    @goToRecoverLink = new CustomLinkView
      cssClass    : 'forgot-link'
      title       : 'Forgot your password?'
      testPath    : 'landing-recover-password'
      href        : '/Recover'

    @goToRegisterLink = new CustomLinkView
      title       : 'Sign up'
      href        : '/Register'

    @formHeader = new KDCustomHTMLView
      tagName     : "h4"
      cssClass    : "form-header"
      click       : (event)->
        return  unless $(event.target).is 'a.register'

    @signupLink = new KDCustomHTMLView
      cssClass  : 'signup-link'
      partial   : @generateFormHeaderPartial()

    @loginForm = new LoginInlineForm
      cssClass : 'login-form'
      testPath : 'login-form'
      callback : @bound 'doLogin'

    @registerForm = new RegisterInlineForm
      cssClass : 'login-form'
      testPath : 'register-form'
      callback : @bound 'showExtraInformation'

    @redeemForm = new RedeemInlineForm
      cssClass : 'login-form'
      callback : @bound 'doRedeem'

    @recoverForm = new RecoverInlineForm
      cssClass : 'login-form'
      callback : @bound 'doRecover'

    @resendForm = new ResendEmailConfirmationLinkInlineForm
      cssClass : 'login-form'
      callback : @bound 'resendEmailConfirmationToken'

    @resetForm = new ResetInlineForm
      cssClass : 'login-form'
      callback : @bound 'doReset'

    @headBanner = new KDCustomHTMLView
      domId    : 'invite-recovery-notification-bar'
      cssClass : 'invite-recovery-notification-bar hidden'
      partial  : '...'

    {oauthController} = KD.singletons

    @githubIcon = new KDCustomHTMLView
      tagName   : 'span'
      cssClass  : 'gh icon'
      click     : -> oauthController.redirectToOauth {provider: 'github'}

    @gplusIcon = new KDCustomHTMLView
      tagName   : 'span'
      cssClass  : 'go icon'
      click     : -> oauthController.redirectToOauth {provider: 'google'}

    @facebookIcon = new KDCustomHTMLView
      tagName   : 'span'
      cssClass  : 'fb icon'
      click     : -> oauthController.redirectToOauth {provider: 'facebook'}

    @twitterIcon = new KDCustomHTMLView
      tagName   : 'span'
      cssClass  : 'tw icon'
      click     : -> oauthController.redirectToOauth {provider: 'twitter'}

    KD.singletons.router.on 'RouteInfoHandled', =>
      @signupModal?.destroy()
      @signupModal = null


  viewAppended:->

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

    KD.utils.defer => @setClass 'shown'

  pistachio:->
      # {{> @loginOptions}}
      # {{> @registerOptions}}
    """
    <div class='tint'></div>
    {{> @logo }}
    <div class="flex-wrapper">
      <div class="form-area">
        {{> @formHeader}}
        <div class="login-form-holder lf">
          {{> @loginForm}}
        </div>
        <div class="login-form-holder rf">
          {{> @registerForm}}
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
      </div>
      <div class="inline-footer">
        <div class="oauth-container">
          <span class='text'></span>
          {{> @githubIcon}}
          {{> @gplusIcon}}
          {{> @facebookIcon}}
          {{> @twitterIcon}}
        </div>
      </div>
      <div class="login-footer">
        {{> @signupLink}} <b>&middot;</b> {{> @goToRecoverLink}}
      </div>
    </div>
    <footer>
      <a href="/Legal" target="_blank">Acceptable user policy</a><a href="/Legal/Copyright" target="_blank">Copyright/DMCA guidelines</a><a href="/Legal/Terms" target="_blank">Terms of service</a><a href="/Legal/Privacy" target="_blank">Privacy policy</a><a href="#{backgroundImages[backgroundImageNr][1]}" target="_blank"><span>photo by </span>#{backgroundImages[backgroundImageNr][0]}</a>
    </footer>
    """

  doReset:({recoveryToken, password})->
    $.ajax
      url       : '/Reset'
      data      : { recoveryToken, password, _csrf : Cookies.get '_csrf' }
      type      : 'POST'
      error     : (xhr) =>
        {responseText} = xhr
        @resetForm.button.hideLoader()
        new KDNotificationView title : responseText
      success   : ({ username }) =>
        @resetForm.button.hideLoader()
        @resetForm.reset()
        @headBanner.hide()

        new KDNotificationView
          title: 'Password changed, you can login now'

        KD.singletons.router.handleRoute '/Login'


  doRecover:({ email })->
    $.ajax
      url         : '/Recover'
      data        : { email, _csrf : Cookies.get '_csrf' }
      type        : 'POST'
      error       : (xhr) =>
        {responseText} = xhr
        new KDNotificationView title : responseText
        @loginForm.button.hideLoader()
      success     : =>
        @recoverForm.reset()
        {entryPoint} = KD.config
        KD.getSingleton('router').handleRoute '/Login', {entryPoint}
        new KDNotificationView
          title     : "Check your email"
          content   : "We've sent you a password recovery code."
          duration  : 4500


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


  showExtraInformation : (formData, form) ->

    form       ?= @registerForm
    {mainView} = KD.singletons

    mainView.setClass 'blur'

    {email, password} = formData

    gravatar = form.gravatars[formData.email]

    unless gravatar

      form.once 'gravatarInfoFetched', =>
        @showExtraInformation formData, form

      return

    {preferredUsername, requestHash} = gravatar

    givenName  = gravatar.name?.givenName
    familyName = gravatar.name?.familyName

    fields = {}
    size   = 80
    src    = KD.utils.getGravatarUrl size, requestHash

    fields.photo =
      itemClass  : KDCustomHTMLView
      tagName    : 'img'
      attributes : { src }

    fields.email =
      itemClass : KDCustomHTMLView
      partial   : email

    fields.username =
      name               : 'username'
      itemClass          : LoginInputView
      label              : 'Pick a username'
      inputOptions       :
        name             : 'username'
        defaultValue     : preferredUsername
        forceCase        : 'lowercase'
        placeholder      : 'username'
        attributes       :
          testpath       : 'register-form-username'
        focus            : -> @parent.icon.unsetTooltip()
        validate         :
          container      : this
          rules          :
            required     : yes
            rangeLength  : [4, 25]
            regExp       : /^[a-z\d]+([-][a-z\d]+)*$/i
            usernameCheck: (input, event) => @usernameCheck input, event
            finalCheck   : (input, event) => @usernameCheck input, event, 0
          messages       :
            required     : 'Please enter a username.'
            regExp       : 'For username only lowercase letters and numbers are allowed!'
            rangeLength  : 'Username should be between 4 and 25 characters!'
          events         :
            required     : 'blur'
            rangeLength  : 'blur'
            regExp       : 'keyup'
            usernameCheck: 'keyup'
            finalCheck   : 'blur'
      nextElement      :
        suffix         :
          itemClass    : KDCustomHTMLView
          cssClass     : 'suffix'
          partial      : '.koding.io'

    if givenName
      fields.firstName =
        defaultValue : givenName
        label        : 'First Name'

    if familyName
      fields.lastName =
        defaultValue : familyName
        label        : 'Last Name'

    fields.recaptcha =
      itemClass : KDCustomHTMLView
      domId     : 'recaptcha'

    USERNAME_VALID       = no
    pendingSignupRequest = no

    @signupModal = new KDModalViewWithForms
      cssClass                        : 'extra-info password'
      # recaptcha has fixed with of 304, hence this value
      width                           : 363
      height                          : 'auto'
      overlay                         : yes
      tabs                            :
        forms                         :
          extraInformation            :
            callback                  : @bound "checkBeforeRegister"
            fields                    : fields
            buttons                   :
              continue                :
                title                 : 'LET\'S GO'
                style                 : 'solid green medium'
                type                  : 'submit'

    @signupModal.setOption 'userData', formData

    usernameView = @signupModal.modalTabs.forms.extraInformation.inputs.username
    usernameView.setOption 'stickyTooltip', yes


    unless gravatar.dummy
      @signupModal.addSubView new KDCustomHTMLView
        partial  : 'Profile info fetched from Gravatar.'
        cssClass : 'description'

    @signupModal.once 'KDObjectWillBeDestroyed', =>
      KD.utils.killWait usernameCheckTimer
      usernameCheckTimer = null

      mainView.unsetClass 'blur'
      form.button.hideLoader()
      form.email.icon.unsetTooltip()
      form.password.icon.unsetTooltip()
      usernameView.icon.unsetTooltip()

      @signupModal = null

    window.onRecaptchaloadCallback = (event) ->
      grecaptcha?.render 'recaptcha', sitekey : KD.config.recaptcha.key

    @signupModal.once 'viewAppended', =>

      if @recaptchaEnabled()
        @recaptcha?.destroy()
        @recaptcha = new KDCustomHTMLView
          tagName    : 'script'
          attributes :
            src      : RECAPTCHA_JS
            async    : yes
            defer    : yes

        @recaptcha.appendToDomBody()

      @signupModal.addSubView new KDCustomHTMLView
        partial : """<div class='hint accept-tos'>By creating an account, you accept Koding's <a href="/Legal/Terms" target="_blank"> Terms of Service</a> and <a href="/Legal/Privacy" target="_blank">Privacy Policy.</a></div>"""

      KD.utils.defer -> usernameView.input.setFocus()

  usernameCheckTimer = null

  usernameCheck: (input, event, delay=800) ->

    return  if event?.which is 9
    return  if input.getValue().length < 4

    KD.utils.killWait usernameCheckTimer
    usernameCheckTimer = null

    input.setValidationResult "usernameCheck", null
    username = input.getValue()

    return  unless input.valid

    usernameCheckTimer = KD.utils.wait delay, =>
      return  unless @signupModal?

      KD.utils.usernameCheck username,
        success : =>

          usernameCheckTimer = null
          return  unless @signupModal?

          input.setValidationResult 'usernameCheck', null
          USERNAME_VALID = yes

          @checkBeforeRegister()  if pendingSignupRequest

        error : ({responseJSON}) =>

          usernameCheckTimer   = null
          pendingSignupRequest = no

          return  unless @signupModal?

          unless responseJSON
            return new KDNotificationView
              title: 'Something went wrong'

          {forbidden, kodingUser} = responseJSON

          USERNAME_VALID = no

          message = switch
            when forbidden
              "Sorry, \"#{username}\" is forbidden to use!"
            when kodingUser
              "Sorry, \"#{username}\" is already taken!"
            else
              "Sorry, there is a problem with \"#{username}\"!"

          input.setValidationResult 'usernameCheck', message


  changeButtonState: (button, state) ->

    if state
      button.setClass 'green'
      button.unsetClass 'red'
      button.enable()
    else
      button.setClass 'red'
      button.unsetClass 'green'
      button.disable()


  recaptchaEnabled: ->

    return KD.config.recaptcha.enabled and KD.utils.getLastUsedProvider() isnt 'github'


  checkBeforeRegister: ->

    return  unless @signupModal?

    {
      username, firstName, lastName
    } = @signupModal.modalTabs.forms.extraInformation.inputs

    if @recaptchaEnabled and grecaptcha?.getResponse() is ''
      return new KDNotificationView title : "Please tell us that you're not a robot!"

    pendingSignupRequest = no

    if USERNAME_VALID and username.input.valid
      formData = @signupModal.getOption "userData"

      formData.recaptcha       = grecaptcha?.getResponse()
      formData.username        = username.input.getValue()
      formData.passwordConfirm = formData.password
      formData.firstName       = firstName?.getValue()
      formData.lastName        = lastName?.getValue()

      @signupModal.destroy()
      @doRegister formData, @registerForm
    else if usernameCheckTimer?
      pendingSignupRequest = yes


  doRegister: (formData, form) ->

    formData.agree = 'on'
    formData._csrf = Cookies.get '_csrf'

    unless formData.referrer
      {mainController}  = KD.singletons
      referrer          = KD.utils.getReferrer() or mainController._referrer
      formData.referrer = referrer  if referrer

    form or= @registerForm
    form.notificationsDisabled = yes
    form.notification?.destroy()

    {username, redirectTo} = formData

    redirectTo ?= ''
    query       = ''

    if redirectTo is 'Pricing'
      { planInterval, planTitle } = formData
      query = KD.utils.stringifyQuery {planTitle, planInterval}
      query = "?#{query}"

    $.ajax
      url         : "/Register"
      data        : formData
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : ->
        KD.utils.removeLastUsedProvider()

        expiration = new Date Date.now() + (60 * 60 * 1000) # an hour
        document.cookie = "newRegister=true;expires=#{expiration.toUTCString()}"

        return location.replace "/#{redirectTo}#{query}"

      error       : (xhr) =>
        {responseText} = xhr
        @showError form, responseText


  showError: (form, message) ->

    form.button.hideLoader()
    form.notificationsDisabled = no
    form.emit 'SubmitFailed', message

    if /duplicate key error/.test message
      form.emit 'EmailError'
    else if /^Errors were encountered during validation/.test message
      if /email/.test message
        form.emit 'EmailError'
      else
        form.emit 'UsernameError'
    else
      new KDNotificationView title: message


  doLogin: (formData) ->

    { mainController } = KD.singletons

    mainController.on 'LoginFailed', =>
      @loginForm.button.hideLoader()
      @$('.flex-wrapper').removeClass 'shake'
      KD.utils.defer => @$('.flex-wrapper').addClass 'animate shake'

    mainController.on 'TwoFactorEnabled', =>
      @loginForm.button.hideLoader()
      @loginForm.tfcode.show()
      @loginForm.tfcode.setFocus()

    mainController.login formData



  doRedeem: -> new KDNotificationView title: "This feature is disabled."

  # doRedeem:({inviteCode})->
    # return  unless KD.config.entryPoint?.slug or KD.isLoggedIn()

    # KD.remote.cacheable KD.config.entryPoint.slug, (err, [group])=>
    #   group.redeemInvitation inviteCode, (err)=>
    #     @redeemForm.button.hideLoader()
    #     return KD.notify_ err.message or err  if err
    #     KD.notify_ 'Success!'
    #     KD.getSingleton('mainController').accountChanged KD.whoami()

  hide: (callback) ->

    @$('.flex-wrapper').removeClass 'expanded'
    @emit "LoginViewHidden"
    @setClass 'hidden'
    callback?()


  show: (callback) ->

    @unsetClass 'hidden'
    @emit "LoginViewShown"
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

  setCustomData: (data) ->

    @setCustomDataToForm 'login', data
    @setCustomDataToForm 'register', data

    @setFormHeaderPartial data


  getRegisterLink: (data = {}) ->

    queryString = KD.utils.stringifyQuery data
    queryString = "?#{queryString}"  if queryString.length > 0

    link = "/Register#{queryString}"


  animateToForm: (name)->

    @unsetClass 'register recover login reset home resendEmail'
    @emit 'LoginViewAnimated', name
    @setClass name
    @$('.flex-wrapper').removeClass 'three one'

    @formHeader.hide()
    @goToRecoverLink.show()

    switch name
      when "register"
        @registerForm.email.input.setFocus()
        @$('.login-footer').hide()
      when "redeem"
        @$('.flex-wrapper').addClass 'one'
        @redeemForm.inviteCode.input.setFocus()
        @$('.inline-footer').hide()
        @$('.login-footer').hide()
      when "login"
        @loginForm.username.input.setFocus()
        if @$('.inline-footer').is ':hidden' then @$('.inline-footer').show()
        if @$('.login-footer').is ':hidden' then @$('.login-footer').show()
      when "recover"
        @$('.flex-wrapper').addClass 'one'
        @goToRecoverLink.hide()
        @recoverForm.usernameOrEmail.input.setFocus()
        @$('.inline-footer').hide()
        @$('.login-footer').hide()
      when "resendEmail"
        @$('.flex-wrapper').addClass 'one'
        @resendForm.usernameOrEmail.input.setFocus()
        @$('.inline-footer').hide()
        @$('.login-footer').hide()
      when "reset"
        @formHeader.show()
        @formHeader.updatePartial "Set your new password below"
        @goToRecoverLink.hide()
        @$('.inline-footer').hide()
        @$('.login-footer').hide()


  generateFormHeaderPartial: (data = {}) ->
    "Don't have an account yet? <a class='register' href='#{@getRegisterLink data}'>Sign up</a>"


  setFormHeaderPartial: (data) ->
    @formHeader.updatePartial @generateFormHeaderPartial data


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
