class FinishRegistrationForm extends RegisterInlineForm
  constructor: ->
    super

    @email.input.setAttribute 'readonly', 'true'

    @password = new LoginInputView
      inputOptions    :
        name          : "password"
        type          : "password"
        testPath      : "recover-password"
        placeholder   : "Enter a new password"
        validate      :
          container   : this
          rules       :
            required  : yes
            minLength : 8
          messages    :
            required  : "Please enter a password."
            minLength : "Passwords should be at least 8 characters."

    @passwordConfirm = new LoginInputView
      inputOptions    :
        name          : "passwordConfirm"
        type          : "password"
        testPath      : "recover-password-confirm"
        placeholder   : "Confirm your password"
        validate      :
          container   : this
          rules       :
            required  : yes
            match     : @password.input
            minLength : 8
          messages    :
            required  : "Please confirm your password."
            match     : "Password confirmation doesn't match!"

    @button = new KDButtonView
      title         : "FINISH REGISTRATION"
      type          : 'submit'
      style         : "solid green"
      loader        : yes

  getEmailValidator: ->

  setRegistrationDetails: (details) ->
    @[key]?.input?.setValue? val  for own key, val of details

  pistachio: ->
    """
    <div class='login-hint'>Complete your registration:</div>
    <div class='email'>{{> @avatar}}{{> @email}}</div>
    <div class='username'>{{> @username}}</div>
    <div>{{> @password}}</div>
    <div>{{> @passwordConfirm}}</div>
    <div>{{> @button}}</div>
    """
