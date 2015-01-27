# This class is responsible of showing the payment modal.
# This workflow will decide if what to do next.
# No matter where you are instantiating this class,
# as long as you pass the view instance to this class
# it will emit necessary events when a substantial thing
# happens in the work flow.
#
# Necessary options when you instantiate it.
#
# planTitle  : string (see PaymentConstants.planTitle)
# monthPrice : int (e.g 1900 for $19)
# yearPrice  : int (e.g 19000 for $190)
class PaymentWorkflow extends KDController

  { TOO_MANY_ATTEMPT_BLOCK_KEY,
    TOO_MANY_ATTEMPT_BLOCK_DURATION } = PaymentConstants

  @getOperation = (current, selected) ->

    arr = [
      PaymentConstants.planTitle.FREE
      PaymentConstants.planTitle.HOBBYIST
      PaymentConstants.planTitle.DEVELOPER
      PaymentConstants.planTitle.PROFESSIONAL
    ]

    current  = arr.indexOf current
    selected = arr.indexOf selected

    return switch
      when selected >  current then PaymentConstants.operation.UPGRADE
      when selected is current then PaymentConstants.operation.INTERVAL_CHANGE
      when selected <  current then PaymentConstants.operation.DOWNGRADE


  getInitialState: -> {
    failedAttemptCount : 0
  }


  constructor: (options = {}, data) ->

    super options, data

    @state = KD.utils.extend @getInitialState(), options.state

    KD.singletons.appManager.tell 'Pricing', 'loadPaymentProvider', @bound 'start'


  start: ->

    operation = PaymentWorkflow.getOperation @state.currentPlan, @state.planTitle

    @state.operation = operation

    { paymentController } = KD.singletons

    paymentController.creditCard (err, card) =>

      @state.paymentMethod = card

      { UPGRADE, DOWNGRADE, INTERVAL_CHANGE } = PaymentConstants.operation

      switch operation
        when DOWNGRADE                then @startDowngradeFlow()
        when UPGRADE, INTERVAL_CHANGE then @startRegularFlow()

      @emit 'WorkflowStarted'


  startRegularFlow: ->

    @modal = new PaymentModal { @state }
    @modal.on 'PaymentWorkflowFinished',          @bound 'finish'
    @modal.on 'PaymentSubmitted',                 @bound 'handlePaymentSubmit'
    @modal.on 'PaymentWorkflowFinishedWithError', @bound 'finishWithError'

    @modal.on 'PaypalButtonClicked', =>
      @state.provider = PaymentConstants.provider.PAYPAL


  startDowngradeFlow: ->

    { paymentController } = KD.singletons

    paymentController.canChangePlan @state.planTitle, (err) =>

      if err?
        @state.error = err
        @modal = new PaymentDowngradeErrorModal { @state }
        return

      @startRegularFlow()


  handlePaymentSubmit: (formData) ->

    { FAILED_ATTEMPT_LIMIT } = PaymentConstants

    if @state.failedAttemptCount >= FAILED_ATTEMPT_LIMIT
      return @failedAttemptLimitReached()

    {
      cardNumber, cardCVC, cardMonth,
      cardYear, planTitle, planInterval, planAmount
      currentPlan, cardName
    } = formData

    # Just because stripe validates both 2 digit
    # and 4 digit year, and different types of month
    # we are enforcing those, other than length problems
    # Stripe will take care of the rest. ~U
    cardYear  = null  unless cardYear.length in [2, 4]
    cardMonth = null  if cardMonth.length isnt 2

    binNumber = cardNumber.slice 0, 6
    lastFour  = cardNumber.slice -4

    KD.utils.defer ->
      KD.singletons.paymentController.logOrder {
        planTitle, planAmount, binNumber, lastFour, cardName
      }, noop

    { KODING, STRIPE } = PaymentConstants.provider

    @state.provider = STRIPE  if @state.provider is KODING

    shouldRegisterNewPlan = \
      currentPlan is PaymentConstants.planTitle.FREE or
      @state.subscriptionState is 'expired'

    if shouldRegisterNewPlan

      Stripe.card.createToken {
        number    : cardNumber
        cvc       : cardCVC
        exp_month : cardMonth
        exp_year  : cardYear
        name      : cardName
      }, (status, response) =>

        if response.error
          @modal.emit 'StripeRequestValidationFailed', response.error
          @modal.form.submitButton.hideLoader()
          @state.failedAttemptCount++
          return

        token = response.id
        @subscribeToPlan planTitle, planInterval, token, {
          binNumber, lastFour, planAmount, cardName
        }
    else
      @subscribeToPlan planTitle, planInterval, 'a', {
        binNumber, lastFour, planAmount, cardName
      }

    @state.currentPlan = planTitle


  subscribeToPlan: (planTitle, planInterval, token, options) ->

    { paymentController } = KD.singletons

    me = KD.whoami()
    me.fetchEmail (err, email) =>

      return KD.showError err  if err

      options.email = email
      options.provider = @state.provider

      paymentController.subscribe token, planTitle, planInterval, options, (err, result) =>

        @modal.form.submitButton.hideLoader()

        if err
          @modal.emit 'PaymentFailed', err
          @state.failedAttemptCount++
        else
          @modal.emit 'PaymentSucceeded'


  failedAttemptLimitReached: (blockUser = yes)->

    KD.utils.defer => @blockUserForTooManyAttempts()  if blockUser

    @modal.emit 'FailedAttemptLimitReached'


  blockUserForTooManyAttempts: ->

    { appStorageController } = KD.singletons

    pricingStorage = appStorageController.storage 'Pricing', '2.0.0'

    value = { timestamp: Date.now() }

    pricingStorage.setValue TOO_MANY_ATTEMPT_BLOCK_KEY, value


  finish: (state) ->

    initiatorView = @getDelegate()

    @emit 'PaymentWorkflowFinishedSuccessfully', state

    initiatorView.state.currentPlan = state.currentPlan

    @modal.destroy()


  finishWithError: (state) ->

    @emit 'PaymentWorkflowFinishedWithError', state

    @destroy()

