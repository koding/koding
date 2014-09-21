# This class is the modal view.
# Shows the payment form and the result of
# the process, (e.g validation errors etc)
class PaymentModal extends KDModalView

  initialState   :
    planInterval : PaymentWorkflow.planInterval.MONTH
    scene        : 0

  constructor: (options = {}, data) ->

    options.width    = 534
    options.cssClass = KD.utils.curry 'payment-modal', options.cssClass
    options.overlay  = yes

    { state } = options

    @state = @utils.extend @initialState, state

    isUpgrade = PaymentWorkflow.isUpgrade @state.currentPlan, @state.planTitle

    if isUpgrade
      options.title    = 'Upgrade Your Plan'
      options.subtitle = ''
    else
      options.title    = 'Downgrade your plan'
      options.subtitle = ''

    super options, data

    @initViews()
    @initEvents()


  initViews: ->
    @addSubView @errors = new KDCustomHTMLView
      cssClass : 'errors hidden'

    @addSubView @form = new PaymentForm { @state }


  initEvents: ->

    @forwardEvent @form, 'PaymentSubmitted'
    @forwardEvent @form, 'PaymentWorkflowFinished'
    @form.forwardEvent this, 'PaymentProviderLoaded'

    @on 'StripeRequestValidationFailed', @bound 'handleStripeFail'
    @on 'PaymentFailed',                 @bound 'handleError'
    @on 'PaymentSucceeded',              @bound 'handleSuccess'



  handleStripeFail: (error) ->
    @form.submitButton.hideLoader()
    @form.showValidationErrorsOnInputs error


  handleError: (error) -> KD.showError error


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


