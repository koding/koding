kd = require 'kd'
LoginViewInlineForm = require './loginviewinlineform'
LoginInputView      = require './logininputview'

module.exports = class ResendEmailConfirmationLinkInlineForm extends LoginViewInlineForm

  constructor: ->

    super
    @usernameOrEmail = new LoginInputView
      inputOptions    :
        name          : 'username-or-email'
        placeholder   : 'username or email'
        testPath      : 'recover-password-input'
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : 'Please enter your username or email.'

    @button = new kd.ButtonView
      title       : 'Resend email'
      style       : 'solid green medium'
      type        : 'submit'
      loader      : yes

  pistachio: ->

    '''
    <div>{{> @usernameOrEmail}}</div>
    <div>{{> @button}}</div>
    '''
