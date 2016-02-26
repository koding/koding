kd               = require 'kd'
KDView           = kd.View
KDInputView      = kd.InputView
KDCustomCheckBox = kd.CustomCheckBox


module.exports = class InvitationInputView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass     = 'invite-inputs'
    options.cancellable ?= yes

    super options, data

    @createElements()


  createElements: ->

    @addSubView @email = new KDInputView
      cssClass     : 'user-email'
      placeholder  : 'mail@example.com'
      validate     :
        rules      :
          required : yes
          email    : yes

    @addSubView @firstName = new KDInputView
      cssClass    : 'firstname'
      placeholder : 'Optional'

    @addSubView @lastName = new KDInputView
      cssClass    : 'lastname'
      placeholder : 'Optional'

    @addSubView @admin = new KDCustomCheckBox
      defaultValue : no

    @inputs = [ @email, @firstName, @lastName, @admin ]


  serialize: ->

    return {
      email     : @email.getValue()
      firstName : @firstName.getValue()
      lastName  : @lastName.getValue()
      role      : if @admin.getValue() then 'admin' else 'member'
    }
