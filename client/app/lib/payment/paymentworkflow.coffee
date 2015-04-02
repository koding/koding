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

kd = require 'kd'
KDController = kd.Controller
PaymentDowngradeErrorModal = require './paymentdowngradeerrormodal'
PaymentDowngradeWithDeletionModal = require './paymentdowngradewithdeletionmodal'
PaymentConstants = require './paymentconstants'
PaymentModal = require './paymentmodal'
whoami = require '../util/whoami'
showError = require '../util/showError'
trackEvent = require 'app/util/trackEvent'
_ = require 'lodash'
ComputeHelpers = require '../providers/computehelpers'


module.exports = class PaymentWorkflow extends KDController

  { TOO_MANY_ATTEMPT_BLOCK_KEY,
    TOO_MANY_ATTEMPT_BLOCK_DURATION } = PaymentConstants

  getInitialState: -> {
    failedAttemptCount : 0
  }


  constructor: (options = {}, data) ->

    super options, data

    @state = kd.utils.extend @getInitialState(), options.state
    @startingState = _.extend {}, @state

    kd.singletons.appManager.tell 'Pricing', 'loadPaymentProvider', @bound 'start'


  start: ->

    operation = PaymentConstants.getOperation @state.currentPlan, @state.planTitle

    @state.operation = operation

    { paymentController } = kd.singletons

    paymentController.canUserPurchase (err, canPurchase) =>

      return @showError err  if err

      unless canPurchase
        return @showError { message: PaymentConstants.error.ERR_USER_NOT_CONFIRMED }

      paymentController.creditCard (err, card) =>

        @state.paymentMethod = card

        { UPGRADE, DOWNGRADE, INTERVAL_CHANGE } = PaymentConstants.operation

        switch operation
          when DOWNGRADE                then @startDowngradeFlow()
          when UPGRADE, INTERVAL_CHANGE then @startRegularFlow()

        @emit 'WorkflowStarted'


  showError: (err) ->

    { message } = err

    humanReadable = PaymentConstants.error[message]
    err.message   = humanReadable  if humanReadable

    showError err
    @modal?.form.submitButton.hideLoader()


  startRegularFlow: ->

    @modal = new PaymentModal { @state }
    @modal.on 'PaymentWorkflowFinished',          @bound 'finish'
    @modal.on 'PaymentWorkflowFinishedWithError', @bound 'finishWithError'

    { paymentController } = kd.singletons

    @modal.on 'PaymentSubmitted', (formData) =>
      paymentController.canUserPurchase (err, confirmed) =>
        return @userIsNotConfirmed err  if err
        @handlePaymentSubmit formData

    @modal.on 'PaypalButtonClicked', =>
      @state.provider = PaymentConstants.provider.PAYPAL


  startDowngradeFlow: ->

    { paymentController } = kd.singletons

    paymentController.canChangePlan @state.planTitle, (err) =>

      if err?
        if @state.planTitle is PaymentConstants.planTitle.FREE
          @modal = new PaymentDowngradeWithDeletionModal { @state }

          @modal.on 'PaymentDowngradeWithDeletionSubmitted', @bound 'handeDowngradeWithDeletion'
          @modal.on 'PaymentWorkflowFinished',               @bound 'finish'
        else
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

    kd.utils.defer ->
      kd.singletons.paymentController.logOrder {
        planTitle, planAmount, binNumber, lastFour, cardName
      }, kd.noop

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

    @subscribeToPlanWithCallback planTitle, planInterval, token, options, (err, result) =>

        @modal.form.submitButton.hideLoader()

        if err
          @modal.emit 'PaymentFailed', err
          @state.failedAttemptCount++
        else
          @modal.emit 'PaymentSucceeded'
          @trackPaymentSucceeded()


  subscribeToPlanWithCallback: (planTitle, planInterval, token, options, callback = kd.noop) ->

    { paymentController } = kd.singletons

    me = whoami()
    me.fetchEmail (err, email) =>

      return @showError err  if err

      options.email = email
      options.provider = @state.provider

      paymentController.subscribe token, planTitle, planInterval, options, callback


  trackPaymentSucceeded: ->

    unless @startingState.currentPlan is PaymentConstants.planTitle.FREE
      return

    trackEvent 'Account upgrade plan, success',
      category : 'userInteraction'
      action   : 'microConversions'
      label    : 'upgradeFreeAccount'

    {planTitle, provider, planInterval} = @state
    planId  = "#{planTitle}-#{planInterval}"

    userId = whoami().getId()
    orderId = "#{userId}-#{planId}"

    {currentPlanInterval, monthPrice, yearPrice} = @state
    if currentPlanInterval is PaymentConstants.planInterval.MONTH
      amount = monthPrice
    else
      amount = yearPrice

    trackEvent 'Completed Order',
      orderId  : orderId
      products : [{
        id       : planId
        title    : planTitle
        interval : planInterval
        category : provider
        quantity : 1
        total    : amount
        currency : 'USD',
    }]


  failedAttemptLimitReached: (blockUser = yes)->

    kd.utils.defer => @blockUserForTooManyAttempts()  if blockUser

    @modal.emit 'FailedAttemptLimitReached'


  blockUserForTooManyAttempts: ->

    { appStorageController } = kd.singletons

    pricingStorage = appStorageController.storage 'Pricing', '2.0.0'

    value = { timestamp: Date.now() }

    pricingStorage.setValue TOO_MANY_ATTEMPT_BLOCK_KEY, value


  finish: (state) ->

    @emit 'PaymentWorkflowFinishedSuccessfully', state

    @modal.destroy()


  finishWithError: (state) ->

    @emit 'PaymentWorkflowFinishedWithError', state

    @destroy()


  handeDowngradeWithDeletion: ->

    { planTitle, planInterval } = @state

    @modal.emit 'DestroyingMachinesStarted'
    ComputeHelpers.destroyExistingMachines (err) =>
      return @modal.emit 'PaymentFailed', err  if err

      @modal.emit 'DowngradingStarted'
      @subscribeToPlanWithCallback planTitle, planInterval, 'a', { }, (err, result) =>
        return @modal.emit 'PaymentFailed', err  if err

        options =
          provider: 'koding'
          redirectAfterCreation: no
        ComputeHelpers.handleNewMachineRequest options, =>
          @modal.emit 'PaymentSucceeded'