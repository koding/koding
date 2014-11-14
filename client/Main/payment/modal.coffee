# This class is the modal view.
# Shows the payment form and the result of
# the process, (e.g validation errors etc)
class PaymentModal extends PaymentBaseModal

  getInitialState: ->
    planInterval : PaymentWorkflow.planInterval.MONTH
    planTitle    : PaymentWorkflow.planTitle.HOBBYIST
    provider     : PaymentWorkflow.provider.KODING
    isUpgrade    : yes


  constructor: (options = {}, data) ->

    { state } = options

    @state = KD.utils.extend @getInitialState(), state

    isUpgrade = PaymentWorkflow.isUpgrade @state.currentPlan, @state.planTitle

    if isUpgrade
      options.title    = 'Upgrades are awesome. Let\'s do this!'
      options.subtitle = ''
    else
      options.title    = 'Downgrade your plan'
      options.subtitle = ''

    super options, data


  initViews: ->

    { provider, isUpgrade, planTitle } = @state
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

    isUpgrade = PaymentWorkflow.isUpgrade currentPlan, planTitle

    if isUpgrade
      @setTitle 'Congratulations! Upgrade successful.'
      @setSubtitle 'Your account has been upgraded to the plan below.'
    else
      @setTitle 'Downgrade complete.'
      @setSubtitle ''

    @form.showSuccess isUpgrade

    @once 'KDModalViewDestroyed', =>
      @emit 'PaymentWorkflowFinished', @state

