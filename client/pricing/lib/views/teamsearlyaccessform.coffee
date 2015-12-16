kd            = require 'kd'
JView         = require 'app/jview'
KDFormView    = kd.FormView
KDInputView   = kd.InputView
KDButtonView  = kd.ButtonView


module.exports = class TeamsEarlyAccessForm extends KDFormView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data

    @button = new KDButtonView
      title         : 'Join Waitlist'
      type          : 'submit'
      cssClass      : 'join-waitlist-button solid green'

    @email = new KDInputView
      placeholder   : 'Email address'
      name          : 'email'
      validate      :
        rules       :
          email     : yes
        messages    :
          email     : 'Please type a valid email address.'


  pistachio: ->
    """
      {{> @email}}
      {{> @button}}
    """


