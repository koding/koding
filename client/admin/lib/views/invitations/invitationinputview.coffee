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
      cssClass    : 'email'
      placeholder : 'name@domain.com'

    @addSubView @firstName = new KDInputView
      cssClass    : 'firstname'
      placeholder : 'first name (optional)'

    @addSubView @lastName = new KDInputView
      cssClass    : 'lastname'
      placeholder : 'last name (optional)'

    @addSubView @loader = new KDLoaderView
      size : width : 16
      showLoader   : yes

    @addSubView @success = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'icon success hidden'

    if cancellable
      @addSubView @cancel = new KDCustomHTMLView
        tagName  : 'span'
        cssClass : 'cancel icon'
        click    : => @destroy()
