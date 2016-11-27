kd = require 'kd'
LoginViewInlineForm = require './loginviewinlineform'
LoginInputView      = require './logininputview'

module.exports = class ResetInlineForm extends LoginViewInlineForm
  constructor: ->
    super
    @password = new LoginInputView
      inputOptions    :
        name          : 'password'
        type          : 'password'
        testPath      : 'recover-password'
        label         : 'New Password'
        placeholder   : 'Enter a new password'
        attributes    :
          autocomplete : 'new-password'
        validate      :
          container   : this
          rules       :
            required  : yes
            minLength : 8
          messages    :
            required  : 'Please enter a password.'
            minLength : 'Passwords should be at least 8 characters.'

    @passwordConfirm = new LoginInputView
      inputOptions    :
        name          : 'passwordConfirm'
        type          : 'password'
        label         : 'Confirm Password'
        testPath      : 'recover-password-confirm'
        placeholder   : 'Confirm the new password'
        attributes    :
          autocomplete : 'new-password'
        validate      :
          container   : this
          rules       :
            required  : yes
            match     : @password.input
            minLength : 8
          messages    :
            required  : 'Please confirm your password.'
            match     : "Password confirmation doesn't match!"

    @button = new kd.ButtonView
      title : 'Reset password'
      style : 'solid green medium'
      type  : 'submit'
      loader: yes

  pistachio: ->
    '''

    <div>{{> @password}}</div>
    <div>{{> @passwordConfirm}}</div>
    <div>{{> @button}}</div>
    '''
