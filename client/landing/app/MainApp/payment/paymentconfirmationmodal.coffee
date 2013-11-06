class PaymentConfirmationModal extends KDModalView

  paymentWarning: do->

    { formatMoney } = KD.utils
    # TODO: Refactor this
    (balance, amount, subscription, type)->
      content = ""

      chargeAmount = Math.max amount - balance, 0

      if type is 'user'
        if subscription.status is "canceled" and amount > 0
          content += "<p>You have a canceled subscription for #{subscription.quantity} x VM(s).
                      To add a new VM, you should re-activate your subscription.</p>"
          if balance > 0
            content += "<p>You also have #{formatMoney balance} credited to your account.</p>"
        else if amount is 0
          content += "<p>You are already subscribed for an extra VM.</p>"
        else if balance > 0
          content += "<p>You have #{formatMoney balance} credited to your account.</p>"

        if chargeAmount > 0
          content += "<p>You will be charged #{formatMoney chargeAmount}.</p>"
        else
          content += "<p>You won't be charged for this VM.</p>"
      else
        if subscription.status is "canceled" and amount > 0
          content += "<p>Your group has a canceled subscription for #{subscription.quantity} x VM(s).
                      To add a new VM, you should re-activate its subscription.</p>"
          if balance > 0
            content += "<p>Your group also has #{formatMoney balance} credited to its account.</p>"
        else if amount is 0
          content += "<p>Your group is already subscribed for an extra VM.</p>"
        else if balance > 0
          content += "<p>Your group has #{formatMoney balance} credited to its account.</p>"

        if chargeAmount > 0
          content += "<p>Your group will be charged #{formatMoney chargeAmount}.</p>"
        else
          content += "<p>Your group won't be charged for this VM.</p>"

  constructor:(options={}, data)->
    {type, plan, needBilling, balance, amount, subscription} = options

    content = @paymentWarning balance, amount, subscription

    if type is 'expensed' and needBilling and 'admin' not in KD.config.roles
      content = 'Group admins have not defined a payment method for this group.'

    options.title     or= 'Confirm VM Creation'
    options.content   or= "<div class='modalformline'>#{content}</div>"
    options.cssClass  or= 'vm-new'
    options.overlay    ?= yes
    options.buttons   or=
      No          :
        title     : 'Close'
        cssClass  : 'modal-clean-gray'
        callback  : @bound 'destroy'
      ReActivate  :
        title     : 'Re-activate plan'
        cssClass  : 'modal-clean-green hidden'
        callback  : =>
          subscription.resume ->
            @buttons.ReActivate.hide()
            @buttons.Yes.show()
      Billing     :
        title     : 'Enter billing info'
        cssClass  : 'modal-clean-green hidden'
        callback  : =>
          @setPaymentInfo type, (success)->
            if success
              if subscription.status is 'canceled'
                @buttons.ReActivate.show()
              else
                @buttons.Yes.show()
              @buttons.Billing.hide()
      Yes         :
        title     : 'OK, create the VM'
        cssClass  : 'modal-clean-green hidden'
        callback  : =>
          @destroy()
          @makePayment type, plan, amount

    super options, data

    modal.on 'KDModalViewDestroyed', cb

    if needBilling
      if type isnt 'expensed'
        modal.buttons.Billing.show()
      else if 'admin' in KD.config.roles
        modal.buttons.Billing.show()
    else
      if subscription.status is 'canceled' and amount > 0
        @buttons.ReActivate.show()
      else
        @buttons.Yes.show()
