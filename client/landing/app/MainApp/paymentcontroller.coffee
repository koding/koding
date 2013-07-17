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

    creditCardPattern = 
    doesValidate  = /((^4[0-9]{12}(?:[0-9]{3})?$)|(^5[1-5][0-9]{14}$)|(^3[47][0-9]{13}$)|(^3(?:0[0-5]|[68][0-9])[0-9]{11}$)|(^6(?:011|5[0-9]{2})[0-9]{12}$)|(^(?:2131|1800|35\d{3})\d{11}$))?/

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
                    regExp        : creditCardPattern
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
                        regExp    : /[0-9]*/
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

    # Credit card icon
    form.fields['cardNumber'].addSubView icon = new KDCustomHTMLView tagName : "span", cssClass : "icon"

    form.inputs['cardNumber'].on "CreditCardTypeIdentified", (type)=>
      cardType = type.toLowerCase()
      $icon = icon.$()
      unless $icon.hasClass cardType
        $icon.removeClass "visa mastercard discover amex"
        $icon.addClass cardType

    form.on "FormValidationFailed", => modal.buttons.Save.hideLoader()

    for k, v of data
      if form.inputs[k]
        if k is "cardNumber" or k is "cardCV"
          form.inputs[k].setPlaceHolder v
        else
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
      else if type is 'expensed'
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
    if type in ['group', 'expensed']
      group.getBillingInfo (e,a)->
        cb e, a
    else
      KD.remote.api.JRecurlyPlan.getUserAccount cb

  createPaymentConfirmationModal: (options, cb)->
    {type, group, plan, needBilling, balance, amount, subscription} = options

    content = @paymentWarning balance, amount, subscription, type

    if type is 'expensed' and needBilling and 'admin' not in KD.config.roles
      content = "Group admins have no defined a payment for this group."

    modal           = new KDModalView
      title         : "Confirm VM Creation"
      content       : "<div class='modalformline'>#{content}</div>"
      cssClass      : "vm-new"
      overlay       : yes
      buttons       :
        No          :
          title     : "Close"
          cssClass  : "modal-clean-gray"
          callback  : =>
            modal.destroy()
        ReActivate  :
          title     : "Re-activate Plan"
          cssClass  : "modal-clean-green hidden"
          callback  : =>
            subscription.resume ->
              modal.buttons.ReActivate.hide()
              modal.buttons.Yes.show()
        Billing     :
          title     : "Enter Billing Info"
          cssClass  : "modal-clean-green hidden"
          callback  : =>
            @setBillingInfo type, group, (success)->
              if success
                if subscription.status is "canceled"
                  modal.buttons.ReActivate.show()
                else
                  modal.buttons.Yes.show()
                modal.buttons.Billing.hide()
        Yes         :
          title     : "OK, create the VM"
          cssClass  : "modal-clean-green hidden"
          callback  : =>
            modal.destroy()
            @makePayment type, plan, amount

    modal.on "KDModalViewDestroyed", ->
      cb()

    if needBilling
      if type isnt 'expensed'
        modal.buttons.Billing.show()
      else if 'admin' in KD.config.roles
        modal.buttons.Billing.show()
    else
      if subscription.status is 'canceled' and amount > 0
        modal.buttons.ReActivate.show()
      else
        modal.buttons.Yes.show()

  paymentWarning: do->

    formatMoney = (amount)-> (amount / 100).toFixed 2

    (balance, amount, subscription, type)->
      content = ""

      chargeAmount = Math.max amount - balance, 0

      if type is 'user'
        if subscription.status is "canceled" and amount > 0
          content += "<p>You have a canceled subscription for #{subscription.quantity} x VM(s).
                      To add a new VM, you should re-activate your subscription.</p>"
          if balance > 0
            content += "<p>You also have $#{formatMoney balance} credited to your account.</p>"
        else if amount is 0
          content += "<p>You are already subscribed for an extra VM.</p>"
        else if balance > 0
          content += "<p>You have $#{formatMoney balance} credited to your account.</p>"

        if chargeAmount > 0
          content += "<p>You will be charged $#{formatMoney chargeAmount}.</p>"
        else
          content += "<p>You won't be charged for this VM.</p>"
      else
        if subscription.status is "canceled" and amount > 0
          content += "<p>Your group has a canceled subscription for #{subscription.quantity} x VM(s).
                      To add a new VM, you should re-activate its subscription.</p>"
          if balance > 0
            content += "<p>Your group also has $#{formatMoney balance} credited to its account.</p>"
        else if amount is 0
          content += "<p>Your group is already subscribed for an extra VM.</p>"
        else if balance > 0
          content += "<p>Your group has $#{formatMoney balance} credited to its account.</p>"

        if chargeAmount > 0
          content += "<p>Your group will be charged $#{formatMoney chargeAmount}.</p>"
        else
          content += "<p>Your group won't be charged for this VM.</p>"

      content += "<p>Do you want to continue?</p>"

      content

  getSubscriptionInfo: do->

    findActiveSubscription = (subs, planCode, callback)->
      info = "none"
      subs.every (sub)->
        if sub.planCode is planCode and sub.status in ['canceled', 'active']
          info = sub
          return no
        return yes
      callback info

    (group, type, planCode, callback)->
      info = "none"
      if type is "group"
        group.checkPayment (err, subs)=>
          findActiveSubscription subs, planCode, callback
      else
        KD.remote.api.JRecurlySubscription.getUserSubscriptions (err, subs)->
          findActiveSubscription subs, planCode, callback

  confirmPayment:(type, plan, callback=->)->
    group = KD.getSingleton("groupsController").getCurrentGroup()

    group.canCreateVM
      type     : type
      planCode : plan.code
    , (err, status)=>
      @getSubscriptionInfo group, type, plan.code, (subscription)=>
        if status
          @createPaymentConfirmationModal {
            needBilling: no
            balance    : 0
            amount     : 0
            type
            group
            plan
            subscription
          }, callback
        else
          @getBillingInfo type, group, (err, account)=>
            needBilling = err or not account or not account.cardNumber

            @getBalance type, group, (err, balance)=>
              if err
                balance = 0
              @createPaymentConfirmationModal {
                amount : plan.feeMonthly
                type
                group
                plan
                subscription
                needBilling
                balance
              }, callback

  makePayment: (type, plan, amount)->
    vmController = KD.getSingleton('vmController')
    group        = KD.getSingleton("groupsController").getCurrentGroup()

    if amount is 0
      vmController.createGroupVM type, plan.code
    else
      if type is 'group'
        group.makePayment
          plan       : plan.code
          multiple   : yes
        , (err, result)->
          unless err
            vmController.createGroupVM type, plan.code
      else if type is 'expensed'
        group.makeExpense
          plan       : plan.code
          multiple   : yes
        , (err, result)->
          if err
            console.log err
          else
            vmController.createGroupVM type, plan.code
      else
        plan.subscribe {multiple: yes}, (err, result)->
          unless err
            vmController.createGroupVM type, plan.code

  createDeleteConfirmationModal: (subscription, cb)->

    if subscription.status is 'canceled'
      content = """<p>Removing this VM will <b>destroy</b> all the data in
                   this VM including all other users in filesystem. <b>Please
                   be careful this process cannot be undone.</b></p>

                   <p>Do you want to continue?</p>"""
    else
      content = """<p>Removing this VM will <b>destroy</b> all the data in
                   this VM including all other users in filesystem. <b>Please
                   be careful this process cannot be undone.</b></p>

                   <p>You can 'pause' your plan instead, and continue using it
                   until #{dateFormat subscription.renew }.</p>

                   <p>What do you want to do?</p>"""

    modal           = new KDModalView
      title         : "Confirm VM Deletion"
      content       : "<div class='modalformline'>#{content}</div>"
      cssClass      : "vm-delete"
      overlay       : yes
      buttons       :
        No          :
          title     : "Cancel"
          cssClass  : "modal-clean-gray"
          callback  : =>
            modal.destroy()
            cb no
        Pause       :
          title     : "Pause Plan"
          cssClass  : "modal-clean-green hidden"
          callback  : =>
            subscription.cancel ->
              modal.destroy()
              cb no
        Delete      :
          title     : "Delete VM"
          cssClass  : "modal-clean-red"
          callback  : =>
            modal.destroy()
            cb yes

    if subscription.status isnt 'canceled'
      modal.buttons.Pause.show()

  deleteVM: (vmInfo, callback)->
    group = KD.getSingleton("groupsController").getCurrentGroup()

    if vmInfo.planOwner.indexOf("user_") > -1
      type = "user"
    else
      type = "group"

    @getSubscriptionInfo group, type, vmInfo.planCode, (subscription)=>
      @createDeleteConfirmationModal subscription, callback