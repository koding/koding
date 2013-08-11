class PaymentController extends KDController

  getBalance: (type, group, callback)->
    if type is 'user'
      KD.remote.api.JRecurlyPlan.getUserBalance callback
    else
      KD.remote.api.JRecurlyPlan.getGroupBalance group, callback

  setBillingInfo: (type, group, callback)->
    @createPaymentMethodModal {}, (newData)=>
      @modal.buttons.Save.hideLoader()
      if type is ['group', 'expensed']
        group.setBillingInfo newData, callback
      else
        KD.remote.api.JRecurlyPlan.setUserAccount newData, callback

  getBillingInfo: (type, group, callback)->
    if type is ['group', 'expensed']
      group.getBillingInfo callback
    else
      KD.remote.api.JRecurlyPlan.getUserAccount callback

  getSubscriptionInfo: do->
    findActiveSubscription = (subs, planCode, callback)->
      subs.reverse().forEach (sub)->
        if sub.planCode is planCode and sub.status in ['canceled', 'active']
          return callback sub

      callback 'none'

    (group, type, planCode, callback)->
      if type is 'group'
        group.checkPayment (err, subs)=>
          findActiveSubscription subs, planCode, callback
      else
        KD.remote.api.JRecurlySubscription.getUserSubscriptions (err, subs)->
          findActiveSubscription subs, planCode, callback

  confirmPayment:(type, plan, callback=->)->
    group = KD.getSingleton('groupsController').getCurrentGroup()
    group.canCreateVM
      type     : type
      planCode : plan.code
    , (err, status)=>
      @getSubscriptionInfo group, type, plan.code, (subscription)=>
        cb = (needBilling, balance, amount)=>
          @createPaymentConfirmationModal {
            needBilling, balance, amount, type, group, plan, subscription
          }, callback

        if status
          cb no, 0, 0
        else
          @getBillingInfo type, group, (err, account)=>
            needBilling = err or not account or not account.cardNumber

            @getBalance type, group, (err, balance)=>
              balance = 0  if err
              cb needBilling, balance, plan.feeMonthly

  makePayment: (type, plan, amount)->
    vmController = KD.getSingleton('vmController')
    group        = KD.getSingleton('groupsController').getCurrentGroup()

    if amount is 0
      vmController.createGroupVM type, plan.code
    else
      if type in ['group', 'expensed']
        group.makePayment
          plan     : plan.code
          multiple : yes
        , (err, result)->
          return KD.showError err  if err
          vmController.createGroupVM type, plan.code
      else
        plan.subscribe multiple: yes, (err, result)->
          return KD.showError err  if err
          vmController.createGroupVM type, plan.code

  deleteVM: (vmInfo, callback)->
    group = KD.getSingleton('groupsController').getCurrentGroup()
    type  =
      if vmInfo.planOwner.indexOf('user_') > -1 then 'user'
      else if vmInfo.type is 'expensed'         then 'expensed'
      else                                           'group'

    @getSubscriptionInfo group, type, vmInfo.planCode,\
      @createDeleteConfirmationModal.bind this, type, callback

  # views

  createPaymentMethodModal:(data, callback) ->
    @modal = new PaymentForm {callback}

    form = @modal.modalTabs.forms['Billing Info']
    form.on 'FormValidationFailed', => modal.buttons.Save.hideLoader()
    form.inputs[k]?.setValue v  for k, v of data

    @modal.on 'KDObjectWillBeDestroyed', => delete @modal
    return @modal

  createPaymentConfirmationModal: (options, callback)->
    options.callback or= callback
    return new PaymentConfirmationModal options

  createDeleteConfirmationModal: (type, callback, subscription)->
    return new PaymentDeleteConfirmationModal {subscription, type, callback}
