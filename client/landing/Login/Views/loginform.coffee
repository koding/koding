class LoginViewInlineForm extends KDFormView

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

    @on "FormValidationFailed", => @loader?.hide()

  pistachio:->

class LoginInlineForm extends LoginViewInlineForm
  constructor:->
    super
    @username = new LoginInputView
      inputOptions    :
        name          : "username"
        forceCase     : "lowercase"
        placeholder   : "username"
        testPath      : "login-form-username"
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : "Please enter a username."

    @password = new LoginInputView
      inputOptions    :
        name          : "password"
        type          : "password"
        placeholder   : "••••••••"
        testPath      : "login-form-password"
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your password."

    # @button = new KDButtonView
    #   title       : "SIGN IN"
    #   style       : "koding-orange"
    #   type        : 'submit'
    #   loader      :
    #     color     : "#ffffff"
    #     diameter  : 21

  resetDecoration:->
    @username.resetDecoration()
    @password.resetDecoration()

  pistachio:->
    """
    <div>{{> @username}}</div>
    <div>{{> @password}}</div>
    """
    # <div>{{> @button}}</div>
