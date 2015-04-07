kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
PaymentBaseModal = require './paymentbasemodal'


module.exports = class PaymentDowngradeErrorModal extends PaymentBaseModal

  getInitialState: -> kd.utils.dict()

  constructor: (options = {}, data) ->

    { state } = options

    @state = kd.utils.extend @getInitialState(), state

    options.title    = 'Downgrading isn\'t possible'
    options.cssClass = kd.utils.curry 'downgrade-error-modal', options.cssClass

    super options, data


  buildErrorPartial = (error) ->
    """
      <div class='msg'>#{error.message}</div>
      <div class='description'>
        <strong>#{error.planTitle.capitalize()} Plan</strong> allows you to have
        <strong>#{error.allowed}</strong> #{error.name}
        but you are currently using <strong>#{error.usage}</strong> #{error.name}.
        Therefore, we cannot process your request for an automatic downgrade.
      </div>
      <div class='description'>
        Please contact us at <a href="mailto:support@koding.com">support@koding.com</a> so that we can help you resolve this.
      </div>
    """


  initViews: ->

    @addSubView @errorMessage = new KDCustomHTMLView
      cssClass : 'downgrade-error-msg'
      partial  : buildErrorPartial @state.error

    @addSubView @closeButton = new KDButtonView
      style    : 'solid medium green'
      cssClass : 'submit-btn'
      partial  : 'CLOSE'
      callback : @bound 'cancel'




