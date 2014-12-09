# This class is the modal view.
# Shows the payment form and the result of
# the process, (e.g validation errors etc)
class PaymentModal extends PaymentBaseModal

  getInitialState: ->
    planInterval : PaymentWorkflow.planInterval.MONTH
    planTitle    : PaymentWorkflow.planTitle.HOBBYIST
    provider     : PaymentWorkflow.provider.KODING
    isUpgrade    : PaymentWorkflow.operation.UPGRADE


  constructor: (options = {}, data) ->

    { state } = options

    @state = KD.utils.extend @getInitialState(), state

    operation = PaymentWorkflow.isUpgrade @state.currentPlan, @state.planTitle

    options.title = switch operation
      when PaymentWorkflow.operation.UPGRADE then 'Upgrades are awesome. Let\'s do this!'
      when PaymentWorkflow.operation.INTERVAL_CHANGE then 'Change your billing cycle'
      when PaymentWorkflow.operation.DOWNGRADE then 'Downgrade your plan'

    options.subtitle = ''

    super options, data


  initViews: ->

    { provider, planTitle } = @state
    { PAYPAL } = PaymentWorkflow.provider
    { FREE }   = PaymentWorkflow.planTitle

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

    { paymentController } = KD.singletons

    paymentController.on 'PaypalRequestFinished', @bound 'handlePaypalResponse'


  handlePaypalNotAllowed: ->

    @setTitle 'Not allowed'
    @form.showPaypalNotAllowedStage()


  handlePaypalResponse: (err) ->

    @form.paypalForm.buttons['paypal'].hideLoader()

    return KD.showError err  if err

    { paymentController } = KD.singletons

    paymentController.subscriptions (err, subscription) =>

      return KD.showError err  if err

      @state = KD.utils.extend @state, subscription

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
    KD.showError msg


  handleSuccess: ->

    { currentPlan, planTitle } = @state

    operation = PaymentWorkflow.isUpgrade currentPlan, planTitle

    switch operation
      when PaymentWorkflow.operation.UPGRADE
        @setTitle 'Congratulations! Upgrade successful'
        @setSubtitle 'Your account has been upgraded to the plan below.'
      when PaymentWorkflow.operation.INTERVAL_CHANGE

        @setTitle 'Billing cycle changed'

      when PaymentWorkflow.operation.DOWNGRADE
        @setTitle 'Downgrade complete.'

    @form.showSuccess operation

    @once 'KDModalViewDestroyed', =>
      @emit 'PaymentWorkflowFinished', @state

