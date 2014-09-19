class PaymentController extends KDController

  STRIPE = "stripe"

  subscribe: (token, planTitle, planInterval, options, callback)->
    params          = {token, planTitle, planInterval}

    params.email    = options.email     if options.email
    params.provider = options.provider  or STRIPE

    @api().subscribe params, callback

  unsubscribe: (plan, provider, callback)->
    @api().unsubscribe {plan, provider}, callback

  subscriptions: (callback)-> @api().subscriptions {}, callback

  invoices: (callback)-> @api().invoices {}, callback

  creditcard: (callback)-> @api().creditcard {}, callback

  updateCreditCard: (token, callback)->
    params          = {token}
    params.provider = options.provider  or STRIPE

    @api().updateCreditCard params, callback

  api:-> KD.remote.api.Payment

