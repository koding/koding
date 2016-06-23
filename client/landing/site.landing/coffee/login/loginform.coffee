kd = require 'kd'
LoginViewInlineForm = require './loginviewinlineform'
LoginInputView      = require './logininputview'

module.exports = class LoginInlineForm extends LoginViewInlineForm

  constructor: ->

    super

    @username = new LoginInputView
      inputOptions    :
        name          : 'username'
        forceCase     : 'lowercase'
        placeholder   : 'Username or Email'
        testPath      : 'login-form-username'
        attributes    :
          testpath    : 'login-form-username'
        validate      :
          rules       :
            required  : yes
          messages    :
            required  : 'Please enter a username.'

    @password = new LoginInputView
      inputOptions    :
        name          : 'password'
        type          : 'password'
        placeholder   : 'Password'
        testPath      : 'login-form-password'
        attributes    :
          testpath    : 'login-form-password'
        validate      :
          rules       :
            required  : yes
          messages    :
            required  : 'Please enter your password.'

    @tfcode = new LoginInputView
      inputOptions    :
        name          : 'tfcode'
        placeholder   : 'Two-Factor Authentication Code'
        testPath      : 'login-form-tfcode'
        attributes    :
          testpath    : 'login-form-tfcode'

    @tfcode.hide()

    @button = new kd.ButtonView
      title       : 'SIGN IN'
      style       : 'solid medium green'
      attributes  :
        testpath  : 'login-button'
      type        : 'submit'
      loader      : yes

    @gitlabButton = new kd.ButtonView
      title       : 'GITLAB LOGIN'
      style       : 'solid medium green'
      loader      : yes
      callback    : ->
        kd.singletons.oauthController.redirectToOauth { provider: 'gitlab' }

  activate: ->
    @username.setFocus()

  resetDecoration: ->
    @username.resetDecoration()
    @password.resetDecoration()
    @tfcode.hide()

  pistachio: ->
    '''
    <div>{{> @username}}</div>
    <div>{{> @password}}</div>
    <div>{{> @tfcode}}</div>
    <div>{{> @button}}</div>
    <div>{{> @gitlabButton}}</div>
    '''
