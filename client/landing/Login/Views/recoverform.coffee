class RecoverInlineForm extends LoginViewInlineForm

  constructor:->

    super
    @usernameOrEmail = new LoginInputView
      inputOptions    :
        name          : "username-or-email"
        placeholder   : "username or email"
        testPath      : "recover-password-input"
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your username or email."

    @button = new KDButtonView
      title       : "Recover password"
      style       : "solid medium green"
      type        : 'submit'
      loader      :
        color     : "#ffffff"
        diameter  : 21

  pistachio:->

    """
    <div>{{> @usernameOrEmail}}</div>
    <div>{{> @button}}</div>
    """
