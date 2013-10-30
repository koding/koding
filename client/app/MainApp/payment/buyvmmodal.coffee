class BuyVmModal extends KDModalView

  constructor: (options = {}, data) ->
    do (o = options) ->
      o.title    ?= "Create a new VM"
      o.cssClass ?= "group-creation-modal"
      o.height   ?= "auto"
      o.width    ?= 500
      o.overlay  ?= yes

    @aggregatedData = {}

    super options, data

  createVmTypeForm: ->
    { hostTypes, descriptions, descPartial, plans } = @getOptions()

    canCreateSharedVM   = "owner" in KD.config.roles or "admin" in KD.config.roles
    canCreatePersonalVM = "member" in KD.config.roles

    group = KD.getSingleton("groupsController").getGroupSlug()

    if canCreateSharedVM
      content = """You can create a <b>Personal</b> or <b>Shared</b> VM for
                   <b>#{group}</b>. If you prefer to create a shared VM, all
                   members in <b>#{group}</b> will be able to use that VM.
                """
    else if canCreatePersonalVM
      content = """You can create a <b>Personal</b> VM in <b>#{group}</b>."""
    else
      return new KDNotificationView
        title : "You are not authorized to create VMs in #{group} group"

    modal = this

    form = new KDFormViewWithFields
      callback              : (formData) =>
        @addAggregateData formData
        @preparePaymentMethods()
      buttons               :
        user                :
          title             : "Create a <b>Personal</b> VM"
          style             : "modal-clean-gray"
          type              : "submit"
          loader            :
            color           : "#ffffff"
            diameter        : 12
          callback          : ->
            form.inputs.type.setValue "user"
        expensed            :
          title             : "Create a <b>Personal</b> VM, Charge Group"
          style             : "modal-clean-gray hidden"
          type              : "submit"
          loader            :
            color           : "#ffffff"
            diameter        : 12
          callback          : ->
            form.inputs.type.setValue "expensed"
        group               :
          title             : "Create a <b>Shared</b> VM"
          style             : "modal-clean-gray hidden"
          type              : "submit"
          loader            :
            color           : "#ffffff"
            diameter        : 12
          callback          : ->
            form.inputs.type.setValue "group"
        cancel              :
          style             : "modal-cancel"
          callback          : -> modal.destroy()
      fields                :
        "intro"             :
          itemClass         : KDCustomHTMLView
          partial           : "<p>#{content}</p>"
        selector            :
          name              : "host"
          itemClass         : HostCreationSelector
          cssClass          : "host-type"
          radios            : hostTypes
          defaultValue      : 0
          validate          :
            rules           :
              required      : yes
            messages        :
              required      : "Please select a VM type!"
          change            : ->
            modal.currentPlan = plans[@getValue()]
        desc                :
          itemClass         : KDCustomHTMLView
          cssClass          : "description-field hidden"
          partial           : descPartial
        type                :
          name              : "type"
          type              : "hidden"
          # Check user quota and show this button only when necessary

    groupObj = KD.getSingleton("groupsController").getCurrentGroup()
    groupObj.checkUserBalance {}, (err, limit=0, balance=0) =>
      warn err  if err

      index      = (parseInt form.inputs.selector.getValue(), 10) or 0
      monthlyFee = plans[index].feeAmount

      if limit > 0
        credits = (limit / 100).toFixed 2

        creditsMessage = "<p>This group gives you $#{credits} credits.</p>"
        if balance > 0
          spent = (balance / 100).toFixed 2
          creditsMessage += "<p>You've spent $#{spent}.</p>"

        form.fields.desc.setPartial creditsMessage
        form.fields.desc.show()

        if limit >= balance + monthlyFee
          modal.modalTabs.forms["Create VM"].buttons.expensed.show()

    hideLoaders = ->
      {group, user, expensed} = form.buttons
      user.hideLoader()
      expensed.hideLoader()
      group.hideLoader()

    # vmController.on "PaymentModalDestroyed", hideLoaders

    form.buttons.group.show()  if canCreateSharedVM

    form.on "FormValidationFailed", hideLoaders

  preparePaymentMethods: (formData) ->
    @setState 'billing choice'

    paymentController = KD.getSingleton 'paymentController'

    paymentField = @choiceForm.fields['Payment method']

    paymentController.fetchPaymentMethods (err, paymentMethods) =>
      return if KD.showError err

      { preferredPaymentMethod, methods, appStorage } = paymentMethods

      switch methods.length

        when 0

          @setState 'billing entry'

        when 1 then do ([method] = methods) =>

          paymentField.addSubView new PaymentMethodView {}, method

          @choiceForm.addCustomData 'paymentMethodId', method.paymentMethodId
          @currentMethod = method

        else

          methodsByPaymentMethodId =
            methods.reduce( (acc, method) ->
              acc[method.paymentMethodId] = method
              acc
            , {})

          defaultPaymentMethod = preferredPaymentMethod ? methods[0].paymentMethodId

          @currentMethod = methodsByPaymentMethodId[defaultPaymentMethod]

          select = new KDSelectBox
            defaultValue  : defaultPaymentMethod
            name          : 'paymentMethodId'
            selectOptions : methods.map (method) ->
              title       : KD.utils.getPaymentMethodTitle method
              value       : method.paymentMethodId
            callback      : (paymentMethodId) =>
              @currentMethod = methodsByPaymentMethodId[paymentMethodId]

          paymentField.addSubView select

  addAggregateData: (formData) ->
    for own key, val of formData
      if @aggregatedData[key]?
        console.warn "Duplicate form data property: #{key}"
      @aggregatedData[key] = val

  getAggregatedData: -> @aggregatedData

  createChoiceForm:->
    form = new KDFormViewWithFields
      callback              : (formData) =>
        @addAggregateData formData
        @setState 'confirm'
      fields                :
        intro               :
          itemClass         : KDCustomHTMLView
          partial           : "<p>Please choose a payment method:</p>"
        paymentMethod       :
          itemClass         : KDCustomHTMLView
          title             : "Payment method"
      buttons               :
        submit              :
          title             : "Use <b>this</b> payment method"
          style             : "modal-clean-gray"
          type              : "submit"
          loader            :
            color           : "#ffffff"
            diameter        : 12
        another             :
          title             : "Use <b>another</b> payment method"
          style             : "modal-clean-gray"
          callback          : =>
            @setState 'billing entry'

  createEntryForm: ->

    form = new PaymentForm

    paymentController = KD.getSingleton 'paymentController'

    paymentController.observePaymentSave form, (err, { paymentMethodId }) =>
      @addAggregateData { paymentMethodId }
      @setState 'confirm'

    form

  getFormNames: ->
    [
      'vmTypeForm'
      'choiceForm'
      'entryForm'
      'confirmForm'
    ]

  hideForms: (forms = @getFormNames()) -> @[form].hide() for form in forms

  setState: (state) ->
    @hideForms()
    switch state
      when 'vm type'          then @vmTypeForm.show()
      when 'billing choice'   then @choiceForm.show()
      when 'billing entry'    then @entryForm.show()
      when 'confirm'
        confirmData = @getAggregatedData()
        confirmData.paymentMethod = @currentMethod
        confirmData.planInfo = @currentPlan
        @confirmForm.setData confirmData
        @confirmForm.show()

  createConfirmForm: -> new BuyVmConfirmView

  processPayment: (formData) ->
    paymentController = KD.getSingleton 'paymentController'

    { type, planInfo: { code: planCode }, paymentMethod: { paymentMethodId } } = formData

    options = { type, planCode, paymentMethodId }
    
    paymentController.makePayment paymentMethodId, planCode, 1

  viewAppended: ->
    super

    @vmTypeForm = @createVmTypeForm()
    @addSubView @vmTypeForm

    @choiceForm = @createChoiceForm()
    @addSubView @choiceForm

    @entryForm = @createEntryForm()
    @addSubView @entryForm

    @confirmForm = @createConfirmForm()
    @addSubView @confirmForm

    @confirmForm.on 'PaymentConfirmed', @bound 'processPayment'

    @setState 'vm type'
