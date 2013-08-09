class PaymentController extends KDController

  getBalance: (type, group, cb)->
    if type is 'user'
      KD.remote.api.JRecurlyPlan.getUserBalance cb
    else
      KD.remote.api.JRecurlyPlan.getGroupBalance group, cb

  setBillingInfo: (type, group, callback)->
    @createPaymentMethodModal {}, (newData)=>
      @modal.buttons.Save.hideLoader()
      if type is 'group'
        group.setBillingInfo newData, callback
      else
        KD.remote.api.JRecurlyPlan.setUserAccount newData, callback

  getBillingInfo: (type, group, cb)->
    if type is 'group'
      group.getBillingInfo cb
    else
      KD.remote.api.JRecurlyPlan.getUserAccount cb

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
          plan: plan.code
        , (err, result)->
          return KD.showError err  if err
          vmController.createGroupVM type, plan.code
      else
        plan.subscribe {}, (err, result)->
          return KD.showError err  if err
          vmController.createGroupVM type, plan.code

  deleteVM: (vmInfo, callback)->
    group = KD.getSingleton("groupsController").getCurrentGroup()

    if vmInfo.planOwner.indexOf("user_") > -1
      type = "user"
    else
      type = "group"

    @getSubscriptionInfo group, type, vmInfo.planCode, (subscription)=>
      @createDeleteConfirmationModal subscription, callback

  # views

  createPaymentMethodModal:(data, callback) ->

    @modal = new PaymentForm {callback}

    form = @modal.modalTabs.forms["Billing Info"]
    form.on "FormValidationFailed", => modal.buttons.Save.hideLoader()
    form.inputs[k]?.setValue v  for k, v of data

    @modal.on "KDObjectWillBeDestroyed", => delete @modal
    return @modal

  createPaymentConfirmationModal: (options, cb)->
    {type, group, plan, needBilling, balance, amount, subscription} = options

    content = @paymentWarning balance, amount, subscription

    modal           = new KDModalView
      title         : "Confirm VM Creation"
      content       : "<div class='modalformline'>#{content}</div>"
      cssClass      : "vm-new"
      overlay       : yes
      buttons       :
        No          :
          title     : "Cancel"
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
      modal.buttons.Billing.show()
    else
      if subscription.status is 'canceled' and amount > 0
        modal.buttons.ReActivate.show()
      else
        modal.buttons.Yes.show()

  paymentWarning: do->

    formatMoney = (amount)-> (amount / 100).toFixed 2

    (balance, amount, subscription)->
      content = ""

      chargeAmount = Math.max amount - balance, 0

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
        content += "<p>You will be charged for $#{formatMoney chargeAmount}.</p>"
      else
        content += "<p>You won't be charged for this VM.</p>"

      content += "<p>Do you want to continue?</p>"

      content

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
