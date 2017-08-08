$                                     = require 'jquery'
kd                                    = require 'kd'
utils                                 = require './../core/utils'

CustomLinkView                        = require './../core/customlinkview'
LoginInputView                        = require './logininputview'
LoginInlineForm                       = require './loginform'
RegisterInlineForm                    = require './registerform'
RedeemInlineForm                      = require './redeemform'
RecoverInlineForm                     = require './recoverform'
ResetInlineForm                       = require './resetform'
ResendEmailConfirmationLinkInlineForm = require './resendmailconfirmationform'
{ getGroupNameFromLocation }          = utils


module.exports = class LoginView extends kd.View

  ENTER                = 13
  USERNAME_VALID       = no
  pendingSignupRequest = no

  constructor: (options = {}, data) ->

    options.cssClass   = 'login-screen login'
    options.attributes =
      testpath         : 'login-container'

    super options, data

    @logo = new kd.CustomHTMLView
      tagName    : 'a'
      cssClass   : 'koding-logo'
      partial    : '<img src=/a/images/logos/header_logo.svg class="main-header-logo">'
      attributes : { href : '/' }

    @backToLoginLink = new CustomLinkView
      title       : 'Sign In'
      href        : '/Login'
      click       : ->

    @goToRecoverLink = new CustomLinkView
      cssClass    : 'forgot-link'
      title       : 'Forgot your password?'
      testPath    : 'landing-recover-password'
      href        : '/Recover'

    @formHeader = new kd.CustomHTMLView
      tagName     : 'h4'
      cssClass    : 'form-header'
      click       : (event) ->
        return  unless $(event.target).is 'a.register'

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

    @headBanner = new kd.CustomHTMLView
      domId    : 'invite-recovery-notification-bar'
      cssClass : 'invite-recovery-notification-bar hidden'
      partial  : '…'

    { oauthController } = kd.singletons

    @githubIcon = new kd.CustomHTMLView
      tagName   : 'span'
      cssClass  : 'gh icon'
      click     : -> oauthController.redirectToOauth { provider: 'github' }

    @gplusIcon = new kd.CustomHTMLView
      tagName   : 'span'
      cssClass  : 'go icon'
      click     : -> oauthController.redirectToOauth { provider: 'google' }

    @facebookIcon = new kd.CustomHTMLView
      tagName   : 'span'
      cssClass  : 'fb icon'
      click     : -> oauthController.redirectToOauth { provider: 'facebook' }

    @twitterIcon = new kd.CustomHTMLView
      tagName   : 'span'
      cssClass  : 'tw icon'
      click     : -> oauthController.redirectToOauth { provider: 'twitter' }

    kd.singletons.router.on 'RouteInfoHandled', =>
      @signupModal?.destroy()
      @signupModal = null


  viewAppended: ->

    super

    query = kd.utils.parseQuery document.location.search.replace '?', ''

    if query.warning
      suffix  = if query.type is 'comment' then 'post a comment' else 'like an activity'
      message = "You need to be logged in to #{suffix}"

      kd.getSingleton('mainView').createGlobalNotification
        title      : message
        type       : 'yellow'
        content    : ''
        closeTimer : 4000
        container  : this

  pistachio: ->
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
      <div class="login-footer">{{> @goToRecoverLink}}</div>
    </div>
    <footer>
      <a href="https://www.koding.com/legal/teams-user-policy" target="_blank">Acceptable user policy</a><a href="https://www.koding.com/legal/teams-copyright" target="_blank">Copyright/DMCA guidelines</a><a href="https://www.koding.com/legal/teams-terms-of-service" target="_blank">Terms of service</a><a href="https://www.koding.com/legal/teams-privacy" target="_blank">Privacy policy</a>
    </footer>
    """

  doReset: ({ recoveryToken, password }) ->
    $.ajax
      url       : '/Reset'
      data      : { recoveryToken, password, _csrf : Cookies.get '_csrf' }
      type      : 'POST'
      error     : (xhr) =>
        { responseText } = xhr
        @resetForm.button.hideLoader()
        new kd.NotificationView { title : responseText }
      success   : ({ username }) =>
        @resetForm.button.hideLoader()
        @resetForm.reset()
        @headBanner.hide()

        new kd.NotificationView
          title: 'Password changed, you can login now'

        kd.singletons.router.handleRoute '/Login'


  doRecover: ({ email }) ->
    $.ajax
      url         : '/Recover'
      data        : { email, _csrf : Cookies.get '_csrf' }
      type        : 'POST'
      error       : (xhr) =>
        { responseText } = xhr
        new kd.NotificationView { title : responseText }
        @loginForm.button.hideLoader()
      success     : =>
        @recoverForm.reset()
        { entryPoint } = kd.config
        kd.getSingleton('router').handleRoute '/Login', { entryPoint }
        new kd.NotificationView
          title     : 'Check your email'
          content   : "We've sent you a password recovery code."
          duration  : 4500


  resendEmailConfirmationToken: (formData) ->
    kd.remote.api.JPasswordRecovery.recoverPassword formData['username-or-email'], (err) =>
      @resendForm.button.hideLoader()
      if err
        new kd.NotificationView
          title : "An error occurred: #{err.message}"
      else
        @resendForm.reset()
        { entryPoint } = kd.config
        kd.getSingleton('router').handleRoute '/Login', { entryPoint }
        new kd.NotificationView
          title     : 'Check your email'
          content   : "We've sent you a confirmation mail."
          duration  : 4500


  showExtraInformation : (formData, form) ->

    form        ?= @registerForm
    { mainView } = kd.singletons

    mainView.setClass 'blur'

    { email, password } = formData

    gravatar = form.gravatars[formData.email]

    unless gravatar

      form.once 'gravatarInfoFetched', =>
        @showExtraInformation formData, form

      return

    { preferredUsername, requestHash } = gravatar

    givenName  = gravatar.name?.givenName
    familyName = gravatar.name?.familyName

    fields = {}
    size   = 80
    src    = utils.getGravatarUrl size, requestHash

    fields.photo =
      itemClass  : kd.CustomHTMLView
      tagName    : 'img'
      attributes : { src }

    fields.email =
      itemClass : kd.CustomHTMLView
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
          itemClass    : kd.CustomHTMLView
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
      itemClass : kd.CustomHTMLView
      domId     : 'recaptcha'

    USERNAME_VALID       = no
    pendingSignupRequest = no

    @signupModal = new kd.ModalViewWithForms
      cssClass                        : 'extra-info password'
      # recaptcha has fixed with of 304, hence this value
      width                           : 363
      height                          : 'auto'
      overlay                         : yes
      tabs                            :
        forms                         :
          extraInformation            :
            callback                  : @bound 'checkBeforeRegister'
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
      @signupModal.addSubView new kd.CustomHTMLView
        partial  : 'Profile info fetched from Gravatar.'
        cssClass : 'description'

    @signupModal.once 'KDObjectWillBeDestroyed', =>
      kd.utils.killWait usernameCheckTimer
      usernameCheckTimer = null

      mainView.unsetClass 'blur'
      form.button.hideLoader()
      form.email.icon.unsetTooltip()
      form.password.icon.unsetTooltip()
      usernameView.icon.unsetTooltip()

      @signupModal = null

    @signupModal.once 'viewAppended', =>

      if @recaptchaEnabled()
        utils.loadRecaptchaScript ->
          grecaptcha?.render 'recaptcha', { sitekey : kd.config.recaptcha.key }

      @signupModal.addSubView new kd.CustomHTMLView
        partial : """<div class='hint accept-tos'>By creating an account, you accept Koding's <a href="/Legal/Terms" target="_blank"> Terms of Service</a> and <a href="/Legal/Privacy" target="_blank">Privacy Policy.</a></div>"""

      kd.utils.defer -> usernameView.input.setFocus()

  usernameCheckTimer = null

  usernameCheck: (input, event, delay = 800) ->

    return  if event?.which is 9
    return  if input.getValue().length < 4

    kd.utils.killWait usernameCheckTimer
    usernameCheckTimer = null

    input.setValidationResult 'usernameCheck', null
    username = input.getValue()

    return  unless input.valid

    usernameCheckTimer = kd.utils.wait delay, =>
      return  unless @signupModal?

      utils.usernameCheck username,
        success : =>

          usernameCheckTimer = null
          return  unless @signupModal?

          input.setValidationResult 'usernameCheck', null
          USERNAME_VALID = yes

          @checkBeforeRegister()  if pendingSignupRequest

        error : ({ responseJSON }) =>

          usernameCheckTimer   = null
          pendingSignupRequest = no

          return  unless @signupModal?

          unless responseJSON
            return new kd.NotificationView
              title: 'Something went wrong'

          { forbidden, kodingUser } = responseJSON

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

    return kd.config.recaptcha.enabled and utils.getLastUsedProvider() isnt 'github'


  checkBeforeRegister: ->

    return  unless @signupModal?

    {
      username, firstName, lastName
    } = @signupModal.modalTabs.forms.extraInformation.inputs

    if @recaptchaEnabled and grecaptcha?.getResponse() is ''
      return new kd.NotificationView { title : "Please tell us that you're not a robot!" }

    pendingSignupRequest = no

    if USERNAME_VALID and username.input.valid
      formData = @signupModal.getOption 'userData'

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
      { mainController } = kd.singletons
      referrer           = utils.getReferrer() or mainController._referrer
      formData.referrer  = referrer  if referrer

    form or= @registerForm
    form.notificationsDisabled = yes
    form.notification?.destroy()

    { username, redirectTo } = formData

    redirectTo ?= ''
    query       = ''

    if redirectTo is 'Pricing'
      { planInterval, planTitle } = formData
      query = kd.utils.stringifyQuery { planTitle, planInterval }
      query = "?#{query}"

    $.ajax
      url         : '/Register'
      data        : formData
      type        : 'POST'
      xhrFields   : { withCredentials : yes }
      success     : ->
        utils.removeLastUsedProvider()

        expiration = new Date Date.now() + (60 * 60 * 1000) # an hour
        document.cookie = "newRegister=true;expires=#{expiration.toUTCString()}"

        return location.replace "/#{redirectTo}#{query}"

      error       : (xhr) =>
        { responseText } = xhr
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
      new kd.NotificationView { title: message }


  doLogin: (formData) ->

    { mainController } = kd.singletons

    mainController.on 'LoginFailed', =>
      @loginForm.button.hideLoader()
      @$('.flex-wrapper').removeClass 'shake'
      kd.utils.defer => @$('.flex-wrapper').addClass 'animate shake'

    mainController.on 'TwoFactorEnabled', =>
      @loginForm.button.hideLoader()
      @loginForm.tfcode.show()
      @loginForm.tfcode.setFocus()

    formData.redirectTo = utils.getLoginRedirectPath('/Login') ? 'IDE'
    mainController.login formData


  doRedeem: -> new kd.NotificationView { title: 'This feature is disabled.' }


  hide: (callback) ->

    @$('.flex-wrapper').removeClass 'expanded'
    @emit 'LoginViewHidden'
    @setClass 'hidden'
    callback?()


  show: (callback) ->

    @unsetClass 'hidden'
    @emit 'LoginViewShown'
    callback?()


  setCustomDataToForm: (type, data) ->
    formName = "#{type}Form"
    @[formName].addCustomData data


  setCustomData: (data) ->

    @setCustomDataToForm 'login', data
    @setCustomDataToForm 'register', data


  getRegisterLink: (data = {}) ->

    queryString = kd.utils.stringifyQuery data
    queryString = "?#{queryString}"  if queryString.length > 0

    link = "/Register#{queryString}"


  animateToForm: (name) ->

    @unsetClass 'register recover login reset home resendEmail'
    @emit 'LoginViewAnimated', name
    @setClass name
    @$('.flex-wrapper').removeClass 'three one'

    @formHeader.hide()
    @goToRecoverLink.show()

    switch name
      when 'register'
        @registerForm.email.input.setFocus()
        @$('.login-footer').hide()
      when 'redeem'
        @$('.flex-wrapper').addClass 'one'
        @redeemForm.inviteCode.input.setFocus()
        @$('.inline-footer').hide()
        @$('.login-footer').hide()
      when 'login'
        @loginForm.username.input.setFocus()
        if @$('.inline-footer').is ':hidden' then @$('.inline-footer').show()
        if @$('.login-footer').is ':hidden' then @$('.login-footer').show()
      when 'recover'
        @$('.flex-wrapper').addClass 'one'
        @goToRecoverLink.hide()
        @recoverForm.usernameOrEmail.input.setFocus()
        @$('.inline-footer').hide()
        @$('.login-footer').hide()
      when 'resendEmail'
        @$('.flex-wrapper').addClass 'one'
        @resendForm.usernameOrEmail.input.setFocus()
        @$('.inline-footer').hide()
        @$('.login-footer').hide()
      when 'reset'
        @formHeader.show()
        @formHeader.updatePartial 'Set your new password below'
        @goToRecoverLink.hide()
        @$('.inline-footer').hide()
        @$('.login-footer').hide()


  getRouteWithEntryPoint: (route) ->
    { entryPoint } = kd.config
    if entryPoint and entryPoint.slug isnt kd.defaultSlug
      return "/#{entryPoint.slug}/#{route}"
    else
      return "/#{route}"

  showError = (err) ->
    if err.code and err.code is 403
      { name, nickname }  = err.data
      kd.getSingleton('appManager').tell 'Account', 'displayConfirmEmailModal', name, nickname

    else if err.message.length > 50
      new kd.ModalView
        title        : 'Something is wrong!'
        width        : 500
        overlay      : yes
        cssClass     : 'new-kdmodal'
        content      : "<div class='modalformline'>" + err.message + '</div>'
    else
      new kd.NotificationView
        title   : err.message
        duration: 1000
