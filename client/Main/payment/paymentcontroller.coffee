class PaymentController extends KDController

  subscribe: (token, planTitle, planInterval, options, callback)->
    params          = {token, planTitle, planInterval}

    params.email    = options.email     if options.email
    params.provider = options.provider  or "stripe"

    @api().subscribe params, callback

  unsubscribe: (plan, provider, callback)->
    @api().unsubscribe {plan, provider}, callback

  subscriptions: (callback)->
    @api().subscriptions {}, callback

  api:-> KD.remote.api.Payment


