LoginViewInlineForm      = require './loginviewinlineform'
LoginInputView           = require './logininputview'
LoginInputViewWithLoader = require './logininputwithloader'

module.exports = class RegisterInlineForm extends LoginViewInlineForm

  EMAIL_VALID    = yes
  USERNAME_VALID = yes
  ENTER          = 13

  constructor:(options={},data)->
    super options, data

    @email = new LoginInputViewWithLoader
      inputOptions    :
        name          : "email"
        placeholder   : "email address"
        testPath      : "register-form-email"
        validate      : @getEmailValidator()
        decorateValidation: no
        focus         : => @email.icon.unsetTooltip()
        keyup         : (event) => @submitForm event  if event.which is ENTER



    @username?.destroy()
    @username = new LoginInputViewWithLoader
      inputOptions       :
        name             : "username"
        forceCase        : "lowercase"
        placeholder      : "username"
        testPath         : "register-form-username"
        focus            : => @username.icon.unsetTooltip()
        keyup            : (event) => @submitForm event  if event.which is ENTER
        validate         :
          container      : this
          rules          :
            required     : yes
            rangeLength  : [4, 25]
            regExp       : /^[a-z\d]+([-][a-z\d]+)*$/i
            usernameCheck: (input, event)=> @usernameCheck input, event
            finalCheck   : (input, event)=> @usernameCheck input, event, 0
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
        decorateValidation: no

    {buttonTitle} = @getOptions()

    @button?.destroy()
    @button = new KDButtonView
      title         : buttonTitle or 'Create account'
      type          : 'button'
      style         : 'solid green medium'
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

  usernameCheckTimer = null

  reset:->
    inputs = KDFormView.findChildInputs this
    input.clearValidationFeedback() for input in inputs
    super

  usernameCheck:(input, event, delay=800)->
    return if event?.which is 9
    return if input.getValue().length < 4

    KD.utils.killWait usernameCheckTimer
    input.setValidationResult "usernameCheck", null
    username = input.getValue()

    if input.valid
      usernameCheckTimer = KD.utils.wait delay, =>
        $.ajax
          url         : "/Validate/Username/#{username}"
          type        : 'POST'
          xhrFields   : withCredentials : yes
          success     : ->
            input.setValidationResult 'usernameCheck', null
            USERNAME_VALID = yes
          error       : ({responseJSON}) ->

            {forbidden, kodingUser} = responseJSON

            if forbidden
              input.setValidationResult "usernameCheck", "Sorry, \"#{username}\" is forbidden to use!"
              USERNAME_VALID = no
            else if kodingUser
              input.setValidationResult "usernameCheck", "Sorry, \"#{username}\" is already taken!"
              USERNAME_VALID = no
            else
              input.setValidationResult "usernameCheck", "Sorry, there is a problem with \"#{username}\"!"
              USERNAME_VALID = no


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


  submitForm: (event) ->

    # KDInputView doesn't give clear results with
    # async results that's why we maintain those
    # results manually in EMAIL_VALID and USERNAME_VALID
    # at least for now - SY
    if EMAIL_VALID and USERNAME_VALID and @username.input.valid and @email.input.valid
      @submit event
      return yes
    else
      @button.hideLoader()
      @username.input.validate()
      @email.input.validate()
      return no


  pistachio:->
    """
    <section class='main-part'>
      <div class='email'>{{> @email}}</div>
      <div class='username'>{{> @username}}</div>
      <div class='invitation-field invited-by hidden'>
        <span class='icon'></span>
        Invited by:
        <span class='wrapper'></span>
      </div>
      <div>{{> @button}}</div>
    </section>
    {{> @invitationCode}}
    """
      # <div>{{> @fullName}}</div>
    #   <div>{{> @password}}</div>
    #   <div>{{> @passwordConfirm}}</div>
