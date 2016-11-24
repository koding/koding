$                        = require 'jquery'
kd                       = require 'kd'
utils                    = require './../core/utils'
LoginViewInlineForm      = require './loginviewinlineform'
LoginInputView           = require './logininputview'
LoginInputViewWithLoader = require './logininputwithloader'

module.exports = class RegisterInlineForm extends LoginViewInlineForm

  ENTER = 13

  constructor: (options = {}, data) ->

    super options, data

    @emailIsAvailable = no
    @gravatars        ?= {}

    @on 'EmailIsAvailable'   , => @emailIsAvailable = yes
    @on 'EmailIsNotAvailable', => @emailIsAvailable = no

    @on 'EmailValidationPassed', @bound 'callbackAfterValidation'

    @password?.destroy()
    @password = new LoginInputView
      inputOptions       :
        name             : 'password'
        type             : 'password'
        attributes        :
          testpath        : 'register-password'
        placeholder      : 'Password'
        focus            : =>
          @password.unsetTooltip()
          return yes
        keydown          : (event) =>
          if event.which is ENTER
            @password.input.validate()
            @button.click event
        validate          :
          container       : this
          rules           :
            required      : yes
            minLength     : 8
          messages        :
            required      : 'Please enter a password.'
            minLength     : 'Passwords should be at least 8 characters.'
        decorateValidation: no

    @email?.destroy()
    @email = new LoginInputViewWithLoader
      inputOptions        :
        name              : 'email'
        placeholder       : 'Email address'
        attributes        :
          testpath        : 'register-form-email'
        validate          : utils.getEmailValidator
          container       : this
          password        : @password
          tfcode          : @tfcode
        decorateValidation: no
        focus             : =>
          @email.unsetTooltip()
          return yes
        blur              : =>
          @fetchGravatarInfo @email.input.getValue()
          return yes
        keydown           : (event) => @submitForm event  if event.which is ENTER
        change            : => @emailIsAvailable = no


    { buttonTitle } = @getOptions()

    @button?.destroy()
    @button = new kd.ButtonView
      title         : buttonTitle or 'CREATE ACCOUNT'
      type          : 'button'
      style         : 'solid green medium'
      attributes    :
        testpath    : 'signup-button'
      loader        : yes
      callback      : @bound 'submitForm'

    @invitationCode = new LoginInputView
      cssClass      : 'hidden'
      inputOptions  :
        name        : 'inviteCode'
        type        : 'hidden'

    @on 'SubmitFailed', (msg) =>
      if msg is 'Wrong password'
        @passwordConfirm.input.setValue ''
        @password.input.setValue ''
        @password.input.validate()

      @button.hideLoader()

    @bind2FAEvents()

    kd.singletons.router.on 'RouteInfoHandled', =>
      @email.unsetTooltip()
      @password.unsetTooltip()


  create2FAInput: ->
    return new LoginInputView
      inputOptions    :
        name          : 'tfcode'
        placeholder   : 'Two-Factor Authentication Code'
        testPath      : 'register-form-tfcode'
        attributes    :
          testpath    : 'register-form-tfcode'
        keydown       : (event) =>
          @submit2FACode()  if event.which is ENTER


  bind2FAEvents: ->

    @on 'TwoFactorEnabled', =>
      modal = new kd.ModalView
        title     : 'Two-Factor Authentication <a href="https://koding.com/docs/2-factor-auth/" target="_blank">What is 2FA?</a>'
        width     : 400
        overlay   : yes
        cssClass  : 'two-factor-code-modal'

      modal.addSubView form = new kd.FormView
      form.addSubView @tfcode = @create2FAInput()
      form.addSubView @createPost2FACodeButton()

      @tfcode.setFocus()


  createPost2FACodeButton: ->

    return @post2FACodeButton = new kd.ButtonView
      title         : 'SIGN IN'
      type          : 'submit'
      style         : 'solid green medium'
      attributes    :
        testpath    : 'signup-button'
      loader        : yes
      callback      : @bound 'submit2FACode'


  submit2FACode: ->

    data =
      email     : @email.input.getValue()
      password  : @password.input.getValue()
      tfcode    : @tfcode.input.getValue()

    if data.tfcode then utils.validateEmail data,
      success : (res) ->
        return location.replace '/'  if res is 'User is logged in!'

      error   : ({ responseText }) =>
        @post2FACodeButton.hideLoader()
        title = if /Bad Request/i.test responseText then 'Access Denied!' else responseText
        new kd.NotificationView { title }
    else
      @post2FACodeButton.hideLoader()


  reset: ->

    inputs = kd.FormView.findChildInputs this
    input.clearValidationFeedback() for input in inputs

    super

  callbackAfterValidation: ->

    @getCallback() @getFormData()  if @password.input.valid


  fetchGravatarInfo : (email) ->

    isEmail = if kd.InputValidator.ruleEmail @email.input then no else yes

    return unless isEmail

    return @emit 'gravatarInfoFetched', @gravatars[email]  if @gravatars[email]

    $.ajax
      url         : '/-/gravatar'
      data        : { email }
      type        : 'POST'
      xhrFields   : { withCredentials : yes }
      success     : (gravatar) =>

        if gravatar is 'User not found'
          gravatar = @getDummyGravatar()
        else
          gravatar = gravatar.entry.first

        @emit 'gravatarInfoFetched', @gravatars[email] = gravatar

      error       : (xhr) =>
        { responseText } = xhr
        console.log "Error while fetching gravatar data - #{responseText}"

        gravatar = @getDummyGravatar()
        @emit 'gravatarInfoFetched', @gravatars[email] = gravatar


  getDummyGravatar: ->

    gravatar =
      dummy               : yes
      photos              : [
        ({ value            : 'https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.80.png' })
      ]
      preferredUsername   : ''

    return gravatar


  submitForm: (event) ->

    # kd.InputView doesn't give clear results with
    # async results that's why we maintain those
    # results manually in @emailIsAvailable
    # at least for now - SY
    if @emailIsAvailable and @password.input.valid and @email.input.valid
      @callbackAfterValidation()
      return yes
    else
      @button.hideLoader()
      @password.input.validate()
      @email.input.validate()
      return no


  handleOauthData: (oauthData) ->

    @oauthData = oauthData
    { input }  = @email

    { username, firstName, lastName } = oauthData

    console.log { oauthData, input }

    if oauthData.email
      input.setValue oauthData.email
      @email.placeholder.setClass 'out'
      @emailIsAvailable = yes
    else
      modal = new KDModalView
        cssClass        : 'fbauth-failed-modal'
        title           : 'OAuth authentication failed'
        content         : 'Sorry, but we could not get a valid email address from your OAuth provider. Please select another method to register.'
        buttons         :
          OK            :
            cssClass    : 'solid green medium'
            title       : 'OK'
            callback    : -> modal.destroy()

    @fetchGravatarInfo input.getValue()

    @once 'gravatarInfoFetched', (gravatar) =>
      # oath username has more priority over gravatar username
      gravatar.preferredUsername = username  if username
      gravatar.name =
        givenName  : firstName
        familyName : lastName

      input.validate()
      @parent.showExtraInformation @getFormData(), this


  pistachio: ->
    """
    <section class='main-part'>
      <div class='email'>{{> @email}}</div>
      <div class='password'>{{> @password}}</div>
      <div class='invitation-field invited-by hidden'>
        <span class='icon'></span>
        Invited by:
        <span class='wrapper'></span>
      </div>
      <div>{{> @button}}</div>
    </section>
    {{> @invitationCode}}
    """
