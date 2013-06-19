class PaymentController extends KDController

  sanitizeRecurlyErrors = (fields, inputs, err) ->
    ERRORS =
      address1             :
        input              : inputs.address1
        field              : fields.address1
      address2             :
        input              : inputs.address2
        field              : fields.address2
      city                 :
        input              : inputs.city
        field              : fields.city
      state                :
        input              : inputs.state
        field              : fields.state
      country              :
        input              : inputs.country
        field              : fields.country
      first_name           :
        input              : inputs.cardFirstName
        field              : fields.cardFirstName
      last_name            :
        input              : inputs.cardLastName
        field              : fields.cardLastName
      number               :
        input              : inputs.cardNumber
        field              : fields.cardNumber
      zip                  :
        input              : inputs.zip
        field              : fields.zip
      verification_value   :
        input              : inputs.cardCV
        field              : fields.cardCV

    for key, val of ERRORS
      val.input.giveValidationFeedback no

    for e in err
      if e.field == 'account.base'
        val.input.showValidationError e.message
        if e.message.indexOf('card') > -1
          inputs.cardNumber.giveValidationFeedback yes
      else
        for key, val of ERRORS
          if e.field.indexOf(key) > -1
            val.input.giveValidationFeedback yes
            inputName = if val.input.inputLabel
              val.input.inputLabel.getTitle()
            else
              inputEl = val.input.$()[0]
              inputEl.getAttribute("placeholder") or inputEl.getAttribute("name") or ""

            val.input.showValidationError "#{inputName} #{e.message}"

  required = (msg)->
    rules    : required  : yes
    messages : required  : msg

  addPaymentMethod:(form, callback) ->
    formData = form.getFormData()

    delete formData.cardNumber  if formData.cardNumber.indexOf('...') > -1
    delete formData.cardCV      if formData.cardCV == 'XXX'


    KD.remote.api.JPayment.setAccount formData, (err, res) =>
      if err
        sanitizeRecurlyErrors form.fields, form.inputs, err
        callback? yes
      else
        sanitizeRecurlyErrors form.fields, form.inputs, []
        KD.remote.api.JPayment.getAccount {}, (e, r) =>
          unless e
            for k, v of r when form.inputs[k]
              form.inputs[k].setValue v
        callback? no

  validatePaymentMethodForm:(formData, callback)->

    return unless @modal

    form    = @modal.modalTabs.forms["Billing Info"]
    button  = @modal.buttons.Save
    onError = (err)->
      warn err
      sanitizeRecurlyErrors form.fields, form.inputs, err
      button.hideLoader()
    onSuccess = @modal.destroy.bind @modal
    callback formData, onError, onSuccess

  createPaymentMethodModal:(data, callback) ->

    @modal = modal = new KDModalViewWithForms
      title                       : "Billing Information"
      width                       : 520
      height                      : "auto"
      cssClass                    : "payments-modal"
      overlay                     : yes
      buttons                     :
        Save                      :
          title                   : "Save"
          style                   : "modal-clean-green"
          type                    : "button"
          loader                  : { color : "#ffffff", diameter : 12 }
          callback                : -> modal.modalTabs.forms["Billing Info"].submit()
      tabs                        :
        navigable                 : yes
        goToNextFormOnSubmit      : no
        forms                     :
          "Billing Info"          :
            callback              : (formData)=>
              @validatePaymentMethodForm formData, callback
            fields                :
              cardFirstName       :
                label             : "Name"
                name              : "cardFirstName"
                placeholder       : "First Name"
                defaultValue      : KD.whoami().profile.firstName
                validate          : required "First name is required!"
                nextElementFlat   :
                  cardLastName    :
                    name          : "cardLastName"
                    placeholder   : "Last Name"
                    defaultValue  : KD.whoami().profile.lastName
                    validate      : required "Last name is required!"
              cardNumber          :
                label             : "Card Number"
                name              : "cardNumber"
                placeholder       : 'Card Number'
                defaultValue      : ''
                validate          :
                  event           : "blur"
                  rules           :
                    creditCard    : yes
                nextElementFlat   :
                  cardCV          :
                    # tooltip       :
                    #   placement   : 'right'
                    #   direction   : 'center'
                    #   title       : 'The location of this verification number depends on the issuer of your credit card'
                    name          : "cardCV"
                    placeholder   : "CV Number"
                    defaultValue  : ""
                    validate      :
                      rules       :
                        required  : yes
                        minLength : 3
                        regExp    : /[0-9]/
                      messages    :
                        required  : "Card security code is required! (CVV)"
                        minLength : "Card security code needs to be at least 3 digits!"
                        regExp    : "Card security code should be a number!"
              cardMonth           :
                label             : "Expire Date"
                itemClass         : KDSelectBox
                name              : "cardMonth"
                selectOptions     : __utils.getMonthOptions()
                defaultValue      : (new Date().getMonth())+2
                nextElementFlat   :
                  cardYear        :
                    itemClass     : KDSelectBox
                    name          : "cardYear"
                    selectOptions : __utils.getYearOptions((new Date().getFullYear()),(new Date().getFullYear()+25))
                    defaultValue  : (new Date().getFullYear())
              address1            :
                label             : "Address"
                name              : "address1"
                placeholder       : "Street Name & Number"
                defaultValue      : ""
                validate          : required "First address field is required!"
              address2            :
                label             : " "
                name              : "address2"
                placeholder       : "Apartment/Suite Number"
              city                :
                label             : "City & State"
                name              : "city"
                placeholder       : "City Name"
                defaultValue      : ""
                validate          : required "City is required!"
                nextElementFlat   :
                  state           :
                    name          : "state"
                    placeholder   : "State"
                    defaultValue  : ""
                    validate      : required "State is required!"
              zip                 :
                label             : "ZIP & Country"
                name              : "zipCode"
                placeholder       : "ZIP Code"
                defaultValue      : ""
                validate          : required "Zip code is required!"
                nextElementFlat   :
                  country         :
                    name          : "country"
                    placeholder   : "Country"
                    defaultValue  : "USA"
                    validate      : required "First address field is required!"

    form = modal.modalTabs.forms["Billing Info"]

    form.on "FormValidationFailed", => modal.buttons.Save.hideLoader()

    for k, v of data
      if form.inputs[k]
        form.inputs[k].setValue v

    modal.on "KDObjectWillBeDestroyed", => delete @modal

    return modal

  deleteAccountPaymentMethod:(callback) ->

    @deleteModal = new KDModalView
      title        : "Warning"
      content      : "<div class='modalformline'>Are you sure you want to delete your billing information?</div>"
      height       : "auto"
      overlay      : yes
      buttons      :
        Yes        :
          loader   :
            color  : "#ffffff"
            diameter : 16
          style    : "modal-clean-gray"
          callback : ->
            KD.remote.api.JPayment.deleteAccountPaymentMethod {}, (err, res) ->
              modal.destroy()
              callback?()

  getBalance: (type, group, cb)->
    if type is 'user'
      KD.remote.api.JRecurlyPlan.getUserBalance cb
    else
      KD.remote.api.JRecurlyPlan.getGroupBalance group, cb

  setBillingInfo: (type, group, cb)->
    @createPaymentMethodModal {}, (newData, onError, onSuccess)->
      if type is 'group'
        group.setBillingInfo newData, (err, result)->
          if err
            onError err
          else
            onSuccess result
            cb yes
      else
        KD.remote.api.JRecurlyPlan.setUserAccount newData, (err, result)->
          if err
            onError err
          else
            onSuccess result
            cb yes

  getBillingInfo: (type, group, cb)->
    if type is 'group'
      group.getBillingInfo cb
    else
      KD.remote.api.JRecurlyPlan.getUserAccount cb

  createPaymentConfirmationModal: (type, group, plan, needBilling, balance, amount, cb)->
    content = @paymentWarning balance, amount

    modal           = new KDModalView
      title         : "Confirm VM Creation"
      content       : "<div class='modalformline'>#{content}</div>"
      overlay       : yes
      buttons       :
        No          :
          title     : "Cancel"
          cssClass  : "modal-clean-gray"
          callback  : =>
            modal.destroy()
            cb()
        Billing     :
          title     : "Enter Billing Info"
          cssClass  : "modal-clean-green hidden"
          callback  : =>
            @setBillingInfo type, group, (success)->
              if success
                modal.buttons.Yes.show()
                modal.buttons.Billing.hide()
        Yes         :
          title     : "OK, create the VM"
          cssClass  : "modal-clean-green hidden"
          callback  : =>
            modal.destroy()
            @makePayment type, plan, amount, ->
              cb()

    if needBilling
      modal.buttons.Billing.show()
    else
      modal.buttons.Yes.show()

  paymentWarning: do->

    formatMoney = (amount)-> (amount / 100).toFixed 2

    (balance, amount)->
      content = ""

      chargeAmount = Math.max amount - balance, 0

      if amount is 0
        content += "<p>You are already subscribed for an extra VM.</p>"
      else if balance > 0
        content += "<p>You have $#{formatMoney balance} credited to your account.</p>"

      if chargeAmount > 0
        content += "<p>You will be charged for $#{formatMoney chargeAmount}</p>"
      else
        content += "<p>You won't be charged for this</p>"

      content

  confirmPayment:(type, plan, callback=->)->
    group = KD.getSingleton("groupsController").getCurrentGroup()

    group.canCreateVM
      type     : type
      planCode : plan.code
    , (err, status)=>
      if not err and status
        @createPaymentConfirmationModal type, group, plan, no, 0, 0, callback
      else
        @getBillingInfo type, group, (err, account)=>
          needBilling = err or not account or not account.cardNumber

          @getBalance type, group, (err, balance)=>
            if err
              balance = 0
            @createPaymentConfirmationModal type, group, plan, needBilling, balance, plan.feeMonthly, callback

  makePayment: (type, plan, amount, callback)->
    vmController = KD.getSingleton('vmController')
    group        = KD.getSingleton("groupsController").getCurrentGroup()

    if amount is 0
      vmController.createGroupVM type, plan.code
    else
      if type is 'group'
        group.makePayment
          plan: plan.code
        , (err, result)->
          unless err
            vmController.createGroupVM type, plan.code
      else
        plan.subscribe {}, (err, result)->
          unless err
            vmController.createGroupVM type, plan.code