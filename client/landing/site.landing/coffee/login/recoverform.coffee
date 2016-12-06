kd                  = require 'kd'
utils               = require './../core/utils'
LoginViewInlineForm = require './loginviewinlineform'
LoginInputView      = require './logininputview'

module.exports = class RecoverInlineForm extends LoginViewInlineForm

  constructor: ->

    super

    { invitation, signup } = utils.getTeamData()
    email = signup?.email or invitation?.email

    @usernameOrEmail = new LoginInputView
      inputOptions    :
        name          : 'email'
        label         : 'Email Address'
        placeholder   : 'Enter your email address'
        testPath      : 'recover-password-input'
        defaultValue  : email
        attributes    :
          autocomplete : 'email'
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : 'Please enter your email.'

    @button = new kd.ButtonView
      title       : 'RECOVER PASSWORD'
      style       : 'solid medium green'
      type        : 'submit'
      loader      : yes


  reset: ->

    super
    @button.hideLoader()

  pistachio: ->

    '''
    <div>{{> @usernameOrEmail}}</div>
    <div>{{> @button}}</div>
    '''
