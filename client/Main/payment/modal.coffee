# This class is the modal view.
# Shows the payment form and the result of
# the process, (e.g validation errors etc)
class PaymentModal extends KDModalView

  initialState   :
    planInterval : PaymentWorkflow.interval.MONTH
    scene        : 0

  constructor: (options = {}, data) ->

    options.title    = 'Upgrade your plan'
    options.subtitle = 'And get some things you know such and such'
    options.width    = 534
    options.cssClass = KD.utils.curry 'payment-modal', options.cssClass

    { state } = options

    @state = @utils.extend @initialState, state

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
    @form.showValidationErrorsOnInputs error


  handleError: (error) -> KD.showError error


  handleSuccess: ->
    @setTitle 'Congratulations!'
    @setSubtitle 'You have been successfully upgraded your plan'
    @form.showSuccess()

