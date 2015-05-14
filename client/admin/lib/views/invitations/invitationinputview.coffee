kd                      = require 'kd'
KDView                  = kd.View
KDInputView             = kd.InputView
KDButtonView            = kd.ButtonView
KDLoaderView            = kd.LoaderView
KDCustomHTMLView        = kd.CustomHTMLView


module.exports = class InvitationInputView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass     = 'invite-inputs'
    options.cancellable ?= yes

    super options, data

    @createElements()


  createElements: ->

    { cancellable } = @getOptions()

    @addSubView @email = new KDInputView
      cssClass     : 'user-email'
      placeholder  : 'name@domain.com'
      validate     :
        rules      :
          required : yes
          email    : yes

    @addSubView @firstName = new KDInputView
      cssClass    : 'firstname'
      placeholder : 'first name (optional)'

    @addSubView @lastName = new KDInputView
      cssClass    : 'lastname'
      placeholder : 'last name (optional)'

    if cancellable
      @addSubView @cancel = new KDCustomHTMLView
        tagName  : 'span'
        cssClass : 'cancel icon'
        click    : => @destroy()
