LoginViewInlineForm      = require './loginviewinlineform'
LoginInputView           = require './logininputview'

module.exports = class RegisterInlineForm extends LoginViewInlineForm

  EMAIL_VALID    = yes
  USERNAME_VALID = yes
  ENTER          = 13

  constructor:(options={},data)->

    super options, data

    @email?.destroy()
    @email = new LoginInputView
      inputOptions    :
        name          : "email"
        placeholder   : "email address"
        testPath      : "register-form-email"
        validate      : @getEmailValidator()
        decorateValidation: no
        focus         : => @email.icon.unsetTooltip()
        keyup         : (event) => @submitForm event  if event.which is ENTER

    @password?.destroy()
    @password = new LoginInputView
      inputOptions    :
        name          : "password"
        type          : "password"
        testPath      : "recover-password"
        placeholder   : "Password"
        validate      :
          container   : this
          rules       :
            required  : yes
            minLength : 8
          messages    :
            required  : "Please enter a password."
            minLength : "Passwords should be at least 8 characters."

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

  # usernameCheck:(input, event, delay=800)->
  #   return if event?.which is 9
  #   return if input.getValue().length < 4

  #   KD.utils.killWait usernameCheckTimer
  #   input.setValidationResult "usernameCheck", null
  #   name = input.getValue()

  #   if input.valid
  #     usernameCheckTimer = KD.utils.wait delay, =>
  #       # @username.loader.show()
  #       KD.remote.api.JUser.usernameAvailable name, (err, response) =>
  #         # @username.loader.hide()
  #         {kodingUser, forbidden} = response
  #         if err
  #           if response?.kodingUser
  #             input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
  #             USERNAME_VALID = no
  #         else
  #           if forbidden
  #             input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is forbidden to use!"
  #             USERNAME_VALID = no
  #           else if kodingUser
  #             input.setValidationResult "usernameCheck", "Sorry, \"#{name}\" is already taken!"
  #             USERNAME_VALID = no
  #           else
  #             input.setValidationResult "usernameCheck", null
  #             USERNAME_VALID = yes


  getEmailValidator: ->
    container   : this
    event       : 'blur'
    rules       :
      required  : yes
      email     : yes
      # available : (input, event) =>
      #   return if event?.which is 9
      #   input.setValidationResult 'available', null
      #   email = input.getValue()
      #   if input.valid
      #     # @email.loader.show()
      #     KD.remote.api.JUser.emailAvailable email, (err, response)=>
      #       # @email.loader.hide()
      #       if err then warn err
      #       else
      #         if response
      #           input.setValidationResult 'available', null
      #           EMAIL_VALID = yes
      #         else
      #           input.setValidationResult 'available', "Sorry, \"#{email}\" is already in use!"
      #           EMAIL_VALID = no
      #   return
    messages    :
      required  : 'Please enter your email address.'
      email     : 'That doesn\'t seem like a valid email address.'


  submitForm: (event) ->

    # KDInputView doesn't give clear results with
    # async results that's why we maintain those
    # results manually in EMAIL_VALID and USERNAME_VALID
    # at least for now - SY
    if EMAIL_VALID and USERNAME_VALID and @password.input.valid and @email.input.valid
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
