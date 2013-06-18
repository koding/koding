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

  subscribeGroup: (group, type, planCode, callback)->
    vmController = KD.getSingleton('vmController')

    # Copy account creator's billing information
    KD.remote.api.JRecurlyPlan.getUserAccount (err, data)=>
      warn err
      if err or not data
        data = {}

      # These will go into Recurly module
      delete data.cardNumber
      delete data.cardMonth
      delete data.cardYear
      delete data.cardCV

      @paymentModal = paymentController.createPaymentMethodModal data, (newData, onError, onSuccess)->
        newData.plan = planCode
        newData.type = type
        group.makePayment newData, (err, subscription)->
          if err
            onError err
          else
            vmController.createGroupVM type, planCode
            onSuccess()
            callback()
      @paymentModal.on "KDModalViewDestroyed", -> vmController.emit "PaymentModalDestroyed"

  subscribeUser: (type, planCode, callback)->
    vmController = KD.getSingleton('vmController')

    KD.remote.api.JRecurlyPlan.getPlanWithCode planCode, (err, plan)->
      plan.subscribe {}, (err, subscription)->
        return callback err  if callback and err
        vmController.createGroupVM type, planCode
        callback?()

  makePaymentModal: (type, plan, callback)->
    vmController      = KD.getSingleton('vmController')
    paymentController = KD.getSingleton('paymentController')

    group = KD.getSingleton("groupsController").getCurrentGroup()
    planCode = plan.code

    group.canCreateVM
      type    : type
      planCode: planCode
    , (err, status)->
      if err
        return new KDNotificationView
          title : "There is an error in payment backend, please try again later."
      if status
        vmController.createGroupVM type, planCode
        callback()
      else
        if type is 'group'
          group.checkPayment (err, payments)->
            if err or payments.length is 0
              paymentController.subscribeGroup group, type, planCode, callback
            else
              group.updatePayment {plan: planCode, type: type}, (err, subscription)->
                vmController.createGroupVM type, planCode
                callback()
        else
          KD.remote.api.JRecurlyPlan.getUserAccount (err, account)->
            if err or not account
              paymentModal = paymentController.createPaymentMethodModal {}, (newData, onError, onSuccess)->
                newData.plan = planCode
                KD.remote.api.JRecurlyPlan.setUserAccount newData, (err, result)->
                  if err
                    onError err
                  else
                    onSuccess result
                    paymentController.subscribeUser type, planCode, callback
              paymentModal.on "KDModalViewDestroyed", -> vmController.emit "PaymentModalDestroyed"
            else
              paymentController.subscribeUser type, planCode, callback