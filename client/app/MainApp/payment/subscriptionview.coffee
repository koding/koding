class SubscriptionView extends JView

  describeSubscription = (quantity, verbPhrase) ->
    """
    Subscription for #{ KD.utils.formatPlural quantity, 'plan' } #{verbPhrase}
    """

  pistachio:->
    { quantity, plan, status, renew, expires, usage } = @getData()

    { feeAmount } = plan

    statusNotice =
      if status in ['active', 'modified']
        describeSubscription quantity, "is active"
      else if status is 'canceled'
        describeSubscription quantity, "will end soon"
      else ''

    dateNotice =
      if plan.type isnt 'single'
        if status is 'active'
          "Plan will renew on #{dateFormat renew}"
        else if status is 'canceled'
          "Plan will be available till #{dateFormat expires}"
      else ''

    displayAmount = KD.utils.formatMoney feeAmount / 100

    """
    <h4>{{#(plan.title)}} - #{displayAmount}</h4>
    <span class='payment-type'>#{statusNotice}</span>
    <p>#{dateNotice}</p>
    """