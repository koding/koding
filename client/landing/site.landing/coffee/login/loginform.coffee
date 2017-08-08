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
        label         : 'Your Username or Email'
        placeholder   : 'Enter your username or email'
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
        label         : 'Your Password'
        placeholder   : 'Enter your password'
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
        label         : '2FA Verification code'
        placeholder   : 'Enter the 6-digit code'
        testPath      : 'login-form-tfcode'
        attributes    :
          testpath    : 'login-form-tfcode'

    @tfcode.hide()

    @button = new kd.ButtonView
      title       : 'SIGN IN'
      style       : 'solid medium green koding'
      icon        : 'koding'
      loader      : yes
      type        : 'submit'
      attributes  :
        testpath  : 'login-button'

    @gitlabButton = new kd.ButtonView
      title       : 'SIGN IN WITH GITLAB'
      style       : 'solid medium green gitlab'
      icon        : 'gitlab'
      loader      :
        color     : '#48BA7D'
      callback    : ->
        kd.singletons.oauthController.redirectToOauth { provider: 'gitlab' }

    @githubButton = new kd.ButtonView
      title       : 'SIGN IN WITH GITHUB'
      style       : 'solid medium green github'
      icon        : 'github'
      loader      :
        color     : '#48BA7D'
      callback    : ->
        kd.singletons.oauthController.redirectToOauth { provider: 'github' }

    @gitlabLogin = new kd.View
      cssClass  : 'gitlab hidden'
      pistachioParams : { @gitlabButton }
      pistachio : '''
        <div class='or'><span>or</span></div>
          {{> gitlabButton}}
        </div>
      '''

    @githubLogin = new kd.View
      cssClass  : 'github hidden'
      pistachioParams : { @githubButton }
      pistachio : '''
        <div class='or'><span>or</span></div>
          {{> githubButton}}
        </div>
      '''

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
    {{> @githubLogin}}
    {{> @gitlabLogin}}
    '''
