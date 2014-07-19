class PaymentWorkflow extends FormWorkflow

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'payment-workflow', options.cssClass
    unless options.confirmForm
      throw new Error "You must provide a confirmForm option!"

    super options, data

  preparePaymentMethods: (formData) ->

    paymentController = KD.getSingleton 'paymentController'

    @showLoader()

    paymentController.fetchPaymentMethods (err, paymentMethods) =>
      @hideLoader()
      return if KD.showError err

      if paymentMethods.methods.length > 0
        (@getForm 'choice').setPaymentMethods paymentMethods
      else
        @clearData 'paymentMethod'

  createChoiceForm: (options, data) ->

    form = new PaymentChoiceForm options, data

    form.once 'Activated', =>
      @preparePaymentMethods()

    form.on 'PaymentMethodChosen', (paymentMethod) =>
      @collectData { paymentMethod }

    form.on 'PaymentMethodNotChosen', =>
      @clearData 'paymentMethod'

    return form

  createEntryForm: (options, data) ->

    form = new PaymentMethodEntryForm options, data

    payment = KD.getSingleton 'paymentController'

    payment.observePaymentSave form, (err, paymentMethod) =>
      form.buttons.Save.hideLoader()
      return if KD.showError err

      @collectData { paymentMethod }

    return form

  prepareWorkflow: ->

    { all, any } = Junction

    @requireData [
      'productData'
      any 'createAccount', 'loggedIn'
      any 'paymentMethod', 'subscription'
      'userConfirmation'
    ]

    if KD.whoami().type is 'unregistered'
      existingAccountWorkflow = new ExistingAccountWorkflow name : 'login' # why, because i had to! srsly, this goes as a form to workflow.on 'FormIsShown' on PricingAppView, and fixes breadcrumb navigation
      existingAccountWorkflow.on 'DataCollected', @bound "collectData"
      @addForm 'createAccount', existingAccountWorkflow, ['createAccount', 'loggedIn']
    else
      # TODO: this is an awful hack for now C.T.
      @addForm 'existingAccount', (@skip loggedIn: yes), ['createAccount', 'loggedIn']

    # - "product form" can be used for collecting some product-related data
    # before the payment method collection/selection process begins.  If you
    # use this feature, make sure to emit the "DataCollected" event with any
    # data that you want aggregated (that you want to be able to access from
    # the "PaymentConfirmed" listeners).
    # - "confirm form" is required.  This form should render a summary, and
    # emit a "PaymentConfirmed" after user approval.
    { productForm, confirmForm } = @getOptions()

    if productForm?

      @addForm 'product', productForm, ['productData', 'subscription']

      productForm.on 'DataCollected', (productData) =>
        @collectData { productData }
        { subscription, oldSubscription } = productData
        @collectData { subscription }  if subscription
        @collectData { oldSubscription }  if oldSubscription

    # "choice form" is for choosing from existing payment methods on-file.
    @addForm 'choice', @createChoiceForm(), ['paymentMethod']

    # "entry form" is for entering a new payment method for us to file.
    @addForm 'entry', @createEntryForm(), ['paymentMethod']

    @addForm 'confirm', confirmForm, ['userConfirmation']

    confirmForm.on 'CouponOptionChanged', (name) => @collectData promotionType: name
    confirmForm.on 'PaymentConfirmed', => @collectData userConfirmation: yes

    @forwardEvent confirmForm, 'Cancel'

    return this
