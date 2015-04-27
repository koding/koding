kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
PaymentBaseModal = require './paymentbasemodal'
PaymentForm = require './paymentform'
PaymentConstants = require './paymentconstants'
showError = require '../util/showError'
trackEvent = require 'app/util/trackEvent'


# This class is the modal view.
# Shows the payment form and the result of
# the process, (e.g validation errors etc)
module.exports = class PaymentModal extends PaymentBaseModal

  { UPGRADE, DOWNGRADE, INTERVAL_CHANGE } = PaymentConstants.operation

  getInitialState: ->
    planInterval : PaymentConstants.planInterval.MONTH
    planTitle    : PaymentConstants.planTitle.HOBBYIST
    provider     : PaymentConstants.provider.KODING
    operation    : PaymentConstants.operation.UPGRADE


  constructor: (options = {}, data) ->

    { state } = options

    @state = kd.utils.extend @getInitialState(), state

    operation = PaymentConstants.getOperation @state.currentPlan, @state.planTitle

    if @state.subscriptionState is 'expired'
      options.title = 'Reactivate your account'
    else
      options.title = switch operation
        when UPGRADE         then 'Upgrades are awesome. Let\'s do this!'
        when INTERVAL_CHANGE then 'Change your billing cycle'
        when DOWNGRADE       then 'Downgrade your plan'

    options.subtitle = ''

    super options, data

    {planTitle, planInterval} = @state

    trackEvent 'Viewed Product',
      id       : "#{planTitle}-#{planInterval}"
      title    : planTitle
      interval : planInterval


  initViews: ->

    { provider, planTitle } = @state
    { PAYPAL } = PaymentConstants.provider
    { FREE }   = PaymentConstants.planTitle

    @addSubView @errors = new KDCustomHTMLView {cssClass : 'errors hidden'}
    @addSubView @form   = new PaymentForm {@state}

    @handlePaypalNotAllowed()  if provider is PAYPAL and planTitle isnt FREE


  initEvents: ->

    @forwardEvent @form, 'PaymentSubmitted'
    @forwardEvent @form, 'PaymentWorkflowFinished'
    @forwardEvent @form, 'PaypalButtonClicked'

    @form.forwardEvent this, 'PaymentProviderLoaded'

    @on 'StripeRequestValidationFailed', @bound 'handleStripeFail'
    @on 'FailedAttemptLimitReached',     @bound 'handleLimitReached'
    @on 'PaymentFailed',                 @bound 'handleError'
    @on 'PaymentSucceeded',              @bound 'handleSuccess'

    { paymentController } = kd.singletons

    paymentController.on 'PaypalRequestFinished', @bound 'handlePaypalResponse'


  handlePaypalNotAllowed: ->

    @setTitle 'Not allowed'
    @form.showPaypalNotAllowedStage()


  handlePaypalResponse: (err) ->

    @form.paypalForm.buttons['paypal'].hideLoader()

    return showError err  if err

    { paymentController } = kd.singletons

    paymentController.subscriptions (err, subscription) =>

      return showError err  if err

      @state = kd.utils.extend @state, subscription

      @handleSuccess()


  handleStripeFail: (error) ->

    @form.submitButton.hideLoader()
    @form.showValidationErrorsOnInputs error


  handleLimitReached: ->

    @setTitle 'Too many failed attempts'
    @setSubtitle ''
    @setClass 'has-problem'

    @form.submitButton.hideLoader()
    @form.showMaximumAttemptFailed()

    @once 'KDModalViewDestroyed', =>
      @emit 'PaymentWorkflowFinishedWithError', @state


  handleError: (error) ->

    msg = error?.description or error?.message or "Something went wrong."
    showError msg


  handleSuccess: ->

    { currentPlan, planTitle } = @state

    operation = PaymentConstants.getOperation currentPlan, planTitle

    switch operation
      when UPGRADE
        @setTitle 'Congratulations! Upgrade successful.'
        @setSubtitle 'Your account has been upgraded to the plan below.'
      when INTERVAL_CHANGE
        @setTitle 'Billing cycle changed'
      when DOWNGRADE
        @setTitle 'Downgrade complete.'

    @form.showSuccess operation

