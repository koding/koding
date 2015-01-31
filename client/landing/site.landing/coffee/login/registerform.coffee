LoginViewInlineForm      = require './loginviewinlineform'
LoginInputView           = require './logininputview'
LoginInputViewWithLoader = require './logininputwithloader'

module.exports = class RegisterInlineForm extends LoginViewInlineForm

  EMAIL_VALID    = yes
  ENTER          = 13

  constructor:(options={},data)->
    super options, data

    @email?.destroy()
    @email = new LoginInputViewWithLoader
      inputOptions        :
        name              : 'email'
        placeholder       : 'Email address'
        attributes        :
          testpath        : 'register-form-email'
        validate          : @getEmailValidator()
        decorateValidation: no
        focus             : => @email.icon.unsetTooltip()
        keyup             : (event) => @submitForm event  if event.which is ENTER
        blur              : => @fetchGravatarInfo @email.input.getValue()

    @password?.destroy()
    @password = new LoginInputView
      inputOptions       :
        name             : "password"
        type             : "password"
        testPath         : "recover-password"
        placeholder      : "Password"
        focus            : => @password.icon.unsetTooltip()
        keyup            : (event) =>
          if event.which is ENTER
            @password.input.validate()
            @button.click event
        validate          :
          event           : 'blur'
          container       : this
          rules           :
            required      : yes
            minLength     : 8
          messages        :
            required      : "Please enter a password."
            minLength     : "Passwords should be at least 8 characters."
        decorateValidation: no

    {buttonTitle} = @getOptions()

    @button?.destroy()
    @button = new KDButtonView
      title         : buttonTitle or 'Create account'
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

    KD.singletons.router.on 'RouteInfoHandled', =>
      @email.icon.unsetTooltip()
      @password.icon.unsetTooltip()


  reset:->

    inputs = KDFormView.findChildInputs this
    input.clearValidationFeedback() for input in inputs

    super


  getEmailValidator: ->
    container   : this
    event       : 'blur'
    rules       :
      required  : yes
      email     : yes
      available : (input, event) =>
        return if event?.which is 9
        input.setValidationResult 'available', null
        email = input.getValue()

        if input.valid
          $.ajax
            url         : "/Validate/Email/#{email}"
            type        : 'POST'
            xhrFields   : withCredentials : yes
            success     : ->
              input.setValidationResult 'available', null
              EMAIL_VALID = yes
            error       : ({responseJSON}) ->
              input.setValidationResult 'available', "Sorry, \"#{email}\" is already in use!"
              EMAIL_VALID = no
    messages    :
      required  : 'Please enter your email address.'
      email     : 'That doesn\'t seem like a valid email address.'


  fetchGravatarInfo : (email) ->

    isEmail = if KDInputValidator.ruleEmail @email.input then no else yes

    return unless isEmail

    @gravatarInfoFetched = no
    @gravatars ?= {}

    return @emit 'gravatarInfoFetched', @gravatars[email]  if @gravatars[email]

    $.ajax
      url         : "/Gravatar"
      data        : {email}
      type        : 'POST'
      xhrFields   : withCredentials : yes
      success     : (gravatar) =>

        if gravatar is "User not found"
          gravatar              =
            dummy               : yes
            photos              : [
              (value            : 'https://koding-cdn.s3.amazonaws.com/square-avatars/default.avatar.80.png')
            ]
            preferredUsername   : ''
        else
          gravatar = gravatar.entry.first

        @emit 'gravatarInfoFetched', @gravatars[email] = gravatar

      error       : (xhr) ->
        {responseText} = xhr
        new KDNotificationView title : responseText


  submitForm: (event) ->

    # KDInputView doesn't give clear results with
    # async results that's why we maintain those
    # results manually in EMAIL_VALID
    # at least for now - SY
    if EMAIL_VALID and @password.input.valid and @email.input.valid
      @submit event
      return yes
    else
      @button.hideLoader()
      @password.input.validate()
      @email.input.validate()
      return no


  pistachio:->
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
