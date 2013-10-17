class BuyVmModal extends KDModalView
  constructor: (options = {}, data) ->
    o = options
    o.title    = "Create a new VM"
    o.cssClass = "group-creation-modal"
    o.height   = "auto"
    o.width    = 500
    o.overlay  = yes

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
          # change            : =>
            # form = modal.modalTabs.forms["Create VM"]
            # {desc, selector} = form.inputs
            # descField        = form.fields.desc
            # descField.show()
            # desc.show()
            # index      = (parseInt selector.getValue(), 10) or 0
            # monthlyFee = (@paymentPlans[index].feeMonthly/100).toFixed(2)
            # desc.$('section').addClass 'hidden'
            # desc.$('section').eq(index).removeClass 'hidden'
            # modal.setPositions()
        desc                :
          itemClass         : KDCustomHTMLView
          cssClass          : "description-field hidden"
          partial           : descPartial
        type                :
          name              : "type"
          type              : "hidden"
          # Check user quota and show this button only when necessary

    groupObj = KD.getSingleton("groupsController").getCurrentGroup()
    groupObj.checkUserBalance {}, (err, limit=0, balance=0)=>
      warn err  if err

      index      = (parseInt form.inputs.selector.getValue(), 10) or 0
      monthlyFee = plans[index].feeMonthly

      if limit > 0
        credits = (limit / 100).toFixed(2)

        creditsMessage = "<p>This group gives you $#{credits} credits.</p>"
        if balance > 0
          spent = (balance / 100).toFixed(2)
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

    paymentField = @paymentMethodChoiceForm.fields['Payment method']

    paymentController = KD.getSingleton 'paymentController'
    paymentController.fetchPaymentMethods (err, paymentMethods) =>
      return KD.showError err  if err

      { defaultMethod, methods, appStorage } = paymentMethods

      if 0 is methods.length
        @setState 'billing entry'
        return

      defaultMethod ?= methods[0].billing.accountCode

      if methods.length is 1

        paymentField.addSubView new BillingMethodView {}, methods[0]
        @paymentMethodChoiceForm.addCustomData 'accountCode', methods[0].accountCode

      else

        paymentField.addSubView new KDSelectBox
          defaultValue  : defaultMethod
          name          : 'accountCode'
          selectOptions : methods.map (method) ->
            title       : KD.utils.getPaymentMethodTitle method
            value       : method.accountCode

  addAggregateData: (formData) ->
    for own key, val of formData
      if @aggregatedData[key]?
        console.warn "Duplicate form data property: #{key}"
      @aggregatedData[key] = val

  getAggregatedData: -> @aggregatedData

  createPaymentMethodChoiceForm:->
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

  createPaymentMethodEntryForm: ->

    form = new BillingForm

    paymentController = KD.getSingleton 'paymentController'
    paymentController.observePaymentSave form, (err, { accountCode }) =>
      @addAggregateData { accountCode }
      @setState 'confirm'

    form

  hideAllForms: ->
    @vmTypeForm.hide()
    @paymentMethodChoiceForm.hide()
    @paymentMethodEntryForm.hide()
    @confirmForm.hide()

  setState: (state) ->
    @hideAllForms()
    switch state
      when 'vm type'          then @vmTypeForm.show()
      when 'billing choice'   then @paymentMethodChoiceForm.show()
      when 'billing entry'    then @paymentMethodEntryForm.show()
      when 'confirm'
        @confirmForm.setData @getAggregatedData()
        @confirmForm.show()

  createConfirmForm: -> new BuyVmConfirmView

  viewAppended: ->
    super

    @vmTypeForm = @createVmTypeForm()
    @addSubView @vmTypeForm

    @paymentMethodChoiceForm = @createPaymentMethodChoiceForm()
    @addSubView @paymentMethodChoiceForm

    @paymentMethodEntryForm = @createPaymentMethodEntryForm()
    @addSubView @paymentMethodEntryForm

    @confirmForm = @createConfirmForm()
    @addSubView @confirmForm

    @setState 'vm type'
