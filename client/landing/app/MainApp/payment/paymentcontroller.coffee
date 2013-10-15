class PaymentController extends KDController

  getGroup = ->
    KD.getSingleton('groupsController').getCurrentGroup()

  getBalance: (type, callback)->

    { JPaymentPlan } = KD.remote.api

    if type is 'user'
      JPaymentPlan.getUserBalance callback
    else
      JPaymentPlan.getGroupBalance callback


  removePaymentMethod: (accountCode, callback) ->
    { JPayment } = KD.remote.api
    JPayment.removePaymentMethod accountCode, callback

  getSubscription: do ->
    findActiveSubscription = (subs, planCode, callback) ->
      subs.reverse().forEach (sub) ->
        if sub.planCode is planCode and sub.status in ['canceled', 'active']
          return callback sub

      callback 'none'

    getSubscription = (type, planCode, callback) ->
      { JPaymentSubscription } = KD.remote.api

      if type is 'group'
        getGroup().checkPayment (err, subs) =>
          findActiveSubscription subs, planCode, callback
      else
        JPaymentSubscription.getUserSubscriptions (err, subs) ->
          findActiveSubscription subs, planCode, callback

  confirmPayment: (type, plan, callback = (->)) ->
    getGroup().canCreateVM { type, planCode: plan.code }, (err, status) =>
      @getSubscription type, plan.code, (subscription) =>
        cb = (needBilling, balance, amount) =>
          @createPaymentConfirmationModal {
            needBilling, balance, amount, type, group, plan, subscription
          }, callback

        if status
          cb no, 0, 0
        else
          @fetchBillingInfo type, group, (err, billing) =>
            needBilling = err or not billing?.cardNumber?

            @getBalance type, group, (err, balance) =>
              balance = 0  if err
              cb needBilling, balance, plan.feeMonthly

  makePayment: (type, plan, amount) ->
    vmController = KD.getSingleton('vmController')

    if amount is 0
      vmController.createGroupVM type, plan.code
    else if type in ['group', 'expensed']
      paymentInfo = { plan: plan.code, multiple: yes }
      getGroup().makePayment paymentInfo, (err, result)->
        return KD.showError err  if err
        vmController.createGroupVM type, plan.code
    else
      plan.subscribe multiple: yes, (err, result)->
        return KD.showError err  if err
        vmController.createGroupVM type, plan.code

  deleteVM: (vmInfo, callback) ->
    type  =
      if (vmInfo.planOwner.indexOf 'user_') > -1 then 'user'
      else if vmInfo.type is 'expensed'          then 'expensed'
      else 'group'

    @getSubscription getGroup(), type, vmInfo.planCode,\
      @createDeleteConfirmationModal.bind this, type, callback

  # views

  fetchBillingInfo: (type, callback) ->

    { JPaymentPlan } = KD.remote.api

    switch type
      when 'group', 'expensed'
        getGroup().fetchBillingInfo callback
      when 'user'
        JPaymentPlan.fetchAccountDetails callback

  updateBillingInfo: (accountCode, billingInfo, callback) ->

    { JPayment } = KD.remote.api

    JPayment.setBillingInfo accountCode, billingInfo, callback


  createBillingInfoModal: ->

    modal = new BillingFormModal
#
#    @fetchCountryData (err, countries, countryOfIp) =>
#      modal.setCountryData { countries, countryOfIp }

    return modal

  fetchCountryData:(callback)->

    { JPayment } = KD.remote.api

    if @countries or @countryOfIp
      return @utils.defer => callback null, @countries, @countryOfIp

    ip = $.cookie 'clientIPAddress'

    JPayment.fetchCountryDataByIp ip, (err, @countries, @countryOfIp) =>
      callback err, @countries, @countryOfIp

  createPaymentConfirmationModal: (options, callback)->
    options.callback or= callback
    return new PaymentConfirmationModal options

  createDeleteConfirmationModal: (type, callback, subscription)->
    return new PaymentDeleteConfirmationModal { subscription, type, callback }
