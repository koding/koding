class PaymentWorkflow extends KDView

  constructor: (options = {}, data) ->
    unless options.confirmForm
      throw new Error "You must provide a confirmForm option!"

    super options, data

    @aggregatedData = {}

  preparePaymentMethods: (formData) ->
    @setState 'choice'

    paymentController = KD.getSingleton 'paymentController'

    paymentField = @choiceForm.fields['Payment method']

    paymentController.fetchPaymentMethods (err, paymentMethods) =>
      return if KD.showError err

      { preferredPaymentMethod, methods, appStorage } = paymentMethods

      switch methods.length

        when 0

          @setState 'entry'

        when 1 then do ([method] = methods) =>

          paymentField.addSubView new PaymentMethodView {}, method

          @choiceForm.addCustomData 'paymentMethod', method

        else

          methodsByPaymentMethodId =
            methods.reduce( (acc, method) ->
              acc[method.paymentMethodId] = method
              acc
            , {})

          defaultPaymentMethod = preferredPaymentMethod ? methods[0].paymentMethodId

          defaultMethod = methodsByPaymentMethodId[defaultPaymentMethod]

          @choiceForm.addCustomData 'paymentMethod', defaultMethod

          select = new KDSelectBox
            defaultValue  : defaultPaymentMethod
            name          : 'paymentMethodId'
            selectOptions : methods.map (method) ->
              title       : KD.utils.getPaymentMethodTitle method
              value       : method.paymentMethodId
            callback      : (paymentMethodId) =>
              chosenMethod = methodsByPaymentMethodId[paymentMethodId]
              @choiceForm.addCustomData 'paymentMethod', chosenMethod

          paymentField.addSubView select

  addAggregateData: (formData) ->
    for own key, val of formData
      if @aggregatedData[key]?
        console.warn "Duplicate form data property: #{key}"
      @aggregatedData[key] = val

  selectPaymentMethod: (method) ->
    { paymentMethodId } = method
    @addAggregateData { paymentMethodId }
    @confirmForm.setPaymentMethod? method
    @setState 'confirm'

  createChoiceForm: ->

    form = new PaymentChoiceForm

    form.on 'PaymentMethodChosen', (method) =>
      @selectPaymentMethod method

    form.on 'PaymentMethodNotChosen', =>
      @setState 'entry'

    form

  createEntryForm: ->

    form = new PaymentForm

    paymentController = KD.getSingleton 'paymentController'

    paymentController.observePaymentSave form, (err, method) =>
      return if KD.showError err

      @selectPaymentMethod method

    form

  getFormNames: ->
    [
      'productForm'
      'choiceForm'
      'entryForm'
      'confirmForm'
    ]

  hideForms: (forms = @getFormNames()) -> @[form]?.hide() for form in forms

  setState: (state) ->
    @hideForms()
    switch state
      when 'product'    then @productForm.show()
      when 'choice'     then @choiceForm.show()
      when 'entry'      then @entryForm.show()
      when 'confirm'
        confirmData = @utils.extend {}, @aggregatedData
        confirmData.planInfo = @currentPlan
        @confirmForm.show()

  viewAppended: ->
    { @productForm } = @getOptions()
    @addSubView @productForm  if @productForm?

    @choiceForm = @createChoiceForm()
    @addSubView @choiceForm

    @entryForm = @createEntryForm()
    @addSubView @entryForm

    { @confirmForm } = @getOptions()
    @addSubView @confirmForm

    @confirmForm.on 'PaymentConfirmed', =>
      @emit 'PaymentConfirmed', @aggregatedData

    if @productForm?
      @setState 'product'
    else
      @preparePaymentMethods()