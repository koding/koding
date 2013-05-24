class ResetInlineForm extends LoginViewInlineForm
  constructor:->
    super
    @password = new LoginInputView
      inputOptions    :
        name          : "password"
        type          : "password"
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
