kd                  = require 'kd'
utils               = require '../../core/utils'
LoginViewInlineForm = require '../../login/loginviewinlineform'
LoginInputView      = require '../../login/logininputview'

module.exports = class FindTeamForm extends LoginViewInlineForm

  constructor: ->

    super

    { invitation, signup } = utils.getTeamData()
    email = signup?.email or invitation?.email

    @usernameOrEmail = new LoginInputView
      inputOptions    :
        name          : 'email'
        placeholder   : 'Email address'
        testPath      : 'find-teams-input'
        defaultValue  : email
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : 'Please enter your email.'

    @button = new kd.ButtonView
      title       : 'FIND YOUR TEAM'
      style       : 'solid medium green'
      type        : 'submit'
      loader      : yes


  reset: ->

    super
    @button.hideLoader()


  setFocus: -> @usernameOrEmail.input.setFocus()


  pistachio: ->

    '''
    <div>{{> @usernameOrEmail}}</div>
    <div>{{> @button}}</div>
    '''
