LoginViewInlineForm = require './loginviewinlineform'
LoginInputView      = require './logininputview'

module.exports = class RecoverInlineForm extends LoginViewInlineForm

  constructor:->

    super
    @usernameOrEmail = new LoginInputView
      inputOptions    :
        name          : "username-or-email"
        placeholder   : "email"
        testPath      : "recover-password-input"
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : "Please enter your email."

    @button = new KDButtonView
      title       : "Recover password"
      style       : "solid medium green"
      type        : 'submit'
      loader      : yes

  pistachio:->

    """
    <div>{{> @usernameOrEmail}}</div>
    <div>{{> @button}}</div>
    """
