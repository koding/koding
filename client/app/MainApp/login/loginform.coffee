class LoginViewInlineForm extends KDFormView

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

    @on "FormValidationFailed", => @button.hideLoader()

  pistachio:->

class LoginInlineForm extends LoginViewInlineForm
  constructor:->
    super
    @username = new LoginInputView
      inputOptions    :
        name          : "username"
        forceCase     : "lowercase"
        placeholder   : "Enter Koding Username"
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
        placeholder   : "Enter Koding Password"
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your password."

    @button = new KDButtonView
      title       : "SIGN IN"
      style       : "koding-orange"
      type        : 'submit'
      loader      :
        color     : "#ffffff"
        diameter  : 21

  resetDecoration:->
    @username.resetDecoration()
    @password.resetDecoration()

  pistachio:->
    """
    <div>{{> @username}}</div>
    <div>{{> @password}}</div>
    <div>{{> @button}}</div>
    """
