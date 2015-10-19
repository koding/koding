kd                = require 'kd'
KDCustomHTMLView  = kd.CustomHTMLView
PaymentBaseModal  = require './paymentbasemodal'
PaymentForm       = require './paymentform'
PaymentConstants  = require './paymentconstants'
showError         = require '../util/showError'
Tracker           = require 'app/util/tracker'


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

    { planTitle, planInterval } = @state


  initViews: ->

    { provider, planTitle, subscriptionState } = @state
    { PAYPAL } = PaymentConstants.provider
    { FREE }   = PaymentConstants.planTitle

    @addSubView @errors = new KDCustomHTMLView {cssClass : 'errors hidden'}
    @addSubView @form   = new PaymentForm {@state}

    if provider is PAYPAL
      if subscriptionState isnt 'expired'
        if planTitle isnt FREE
          @handlePaypalNotAllowed()


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

    @setTitle 'Action not allowed'
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

    { currentPlan, planInterval, planTitle } = @state

    operation = PaymentConstants.getOperation currentPlan, planTitle

    switch operation
      when UPGRADE
        @setTitle 'Congratulations! Upgrade successful.'
        @setSubtitle 'Your account has been upgraded to the plan below.'
        action = Tracker.PLAN_UPGRADED
      when INTERVAL_CHANGE
        @setTitle 'Billing cycle changed'
        action = Tracker.BILLING_CYCLE_CHANGED
      when DOWNGRADE
        @setTitle 'Downgrade complete.'
        action = Tracker.PLAN_DOWNGRADED

    Tracker.track action, { category: planTitle, label: planInterval }

    @form.showSuccess operation
