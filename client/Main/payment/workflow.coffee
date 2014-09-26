# This class is responsible of showing the payment modal.
# This workflow will decide if what to do next.
# No matter where you are instantiating this class,
# as long as you pass the view instance to this class
# it will emit necessary events when a substantial thing
# happens in the work flow.
#
# Necessary options when you instantiate it.
#
# planTitle  : string (see PaymentWorkflow.planTitle)
# monthPrice : int (e.g 1900 for $19)
# yearPrice  : int (e.g 19000 for $190)
class PaymentWorkflow extends KDController

  @planInterval =
    MONTH       : 'month'
    YEAR        : 'year'

  @planTitle =
    FREE         : 'free'
    HOBBYIST     : 'hobbyist'
    DEVELOPER    : 'developer'
    PROFESSIONAL : 'professional'

  @isUpgrade = (current, selected) ->

    arr = [
      PaymentWorkflow.planTitle.FREE
      PaymentWorkflow.planTitle.HOBBYIST
      PaymentWorkflow.planTitle.DEVELOPER
      PaymentWorkflow.planTitle.PROFESSIONAL
    ]

    (arr.indexOf selected) > (arr.indexOf current)


  getInitialState: -> KD.utils.dict()


  constructor: (options = {}, data) ->

    super options, data

    @state = KD.utils.extend @getInitialState(), options.state

    KD.singletons.appManager.tell 'Pricing', 'loadPaymentProvider', @bound 'start'


  start: ->

    isUpgrade = PaymentWorkflow.isUpgrade @state.currentPlan, @state.planTitle

    if isUpgrade
    then @startRegularFlow()
    else @startDowngradeFlow()


  startRegularFlow: ->

    @modal = new PaymentModal { @state }
    @modal.on 'PaymentWorkflowFinished', @bound 'finish'
    @modal.on "PaymentSubmitted",        @bound 'handlePaymentSubmit'


  startDowngradeFlow: ->

    { paymentController } = KD.singletons

    paymentController.canChangePlan @state.planTitle, (err) =>

      if err?
        @state.error = err
        @modal = new PaymentDowngradeErrorModal { @state }
        return

      @startRegularFlow()


  handlePaymentSubmit: (formData) ->

    {
      cardNumber, cardCVC, cardMonth,
      cardYear, planTitle, planInterval,
      currentPlan
    } = formData

    # Just because stripe validates both 2 digit
    # and 4 digit year, and different types of month
    # we are enforcing those, other than length problems
    # Stripe will take care of the rest. ~U
    cardYear  = null  if cardYear.length isnt 4
    cardMonth = null  if cardMonth.length isnt 2

    if currentPlan is PaymentWorkflow.planTitle.FREE

      Stripe.card.createToken {
        number    : cardNumber
        cvc       : cardCVC
        exp_month : cardMonth
        exp_year  : cardYear
      } , (status, response) =>

        if response.error
          @modal.emit 'StripeRequestValidationFailed', response.error
          @modal.form.submitButton.hideLoader()
          return

        token = response.id
        @subscribeToPlan planTitle, planInterval, token
    else
      @subscribeToPlan planTitle, planInterval, 'a'

    @state.currentPlan = planTitle


  subscribeToPlan: (planTitle, planInterval, token = 'a') ->
    { paymentController } = KD.singletons

    me = KD.whoami()
    me.fetchEmail (err, email) =>

      return KD.showError err  if err

      obj = { email }

      paymentController.subscribe token, planTitle, planInterval, obj, (err, result) =>
        @modal.form.submitButton.hideLoader()

        if err
        then @modal.emit 'PaymentFailed', err
        else @modal.emit 'PaymentSucceeded'


  finish: (state) ->

    initiatorView = @getDelegate()

    @emit 'PaymentWorkflowFinishedSuccessfully', state

    initiatorView.state.currentPlan = state.currentPlan

    @modal.destroy()


