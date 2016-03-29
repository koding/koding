kd = require 'kd'
LoginViewInlineForm = require './loginviewinlineform'
LoginInputView      = require './logininputview'

module.exports = class RedeemInlineForm extends LoginViewInlineForm

  constructor: (options = {}, data) ->
    super options, data

    @inviteCode = new LoginInputView
      inputOptions    :
        name          : 'inviteCode'
        placeholder   : 'Enter your invite code'
        validate      :
          container   : this
          rules       :
            required  : yes
          messages    :
            required  : 'Please enter your invite code.'

    @button = new kd.ButtonView
      title       : 'REDEEM'
      style       : 'solid medium green'
      type        : 'submit'
      loader      : yes

  pistachio: ->
    '''
    <div>{{> @inviteCode}}</div>
    <div>{{> @button}}</div>
    '''
