kd                  = require 'kd'
utils               = require './../core/utils'
LoginViewInlineForm = require './../login/loginviewinlineform'
LoginInputView      = require './../login/logininputview'

module.exports = class FindTeamForm extends LoginViewInlineForm

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'login-form', options.cssClass

    super options, data

    { invitation, signup } = utils.getTeamData()
    email = signup?.email or invitation?.email

    @usernameOrEmail = new LoginInputView
      inputOptions             :
        name                   : 'email'
        placeholder            : 'Email address...'
        testPath               : 'find-team-input'
        defaultValue           : email
        validate               :
          container            : this
          rules                :
            required           : yes
          messages             :
            required           : 'Please enter your email.'

    @button = new kd.ButtonView
      title       : 'SEND TEAM LIST'
      style       : 'TeamsModal-button'
      type        : 'submit'
      loader      : yes


  reset: ->

    super
    @button.hideLoader()


  setFocus: -> @usernameOrEmail.input.setFocus()


  pistachio: ->

    '''
    {{> @usernameOrEmail}}
    {{> @button}}
    '''
