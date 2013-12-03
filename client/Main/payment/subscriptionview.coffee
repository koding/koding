class SubscriptionView extends JView

  describeSubscription = (quantity, verbPhrase) ->
    """
    Subscription for #{ KD.utils.formatPlural quantity, 'plan' } #{verbPhrase}
    """

  pistachio:->
    { quantity, plan, status, renew, expires, usage, startsAt } = @getData()

    { feeAmount } = plan

    statusNotice = switch status
      when 'active', 'modified'
        describeSubscription quantity, "is active"
      when 'canceled'
        describeSubscription quantity, "will end soon"
      when 'future'
        describeSubscription quantity, "will begin soon"
      else ''

    dateNotice =
      if plan.type isnt 'single'
        switch status
          when 'active'
            "Plan will renew on #{dateFormat renew}"
          when 'canceled'
            "Plan will be available till #{dateFormat expires}"
          when 'future'
            "Plan will become available on #{dateFormat startsAt}"
      else ''

    displayAmount = KD.utils.formatMoney feeAmount / 100

    """
    <h4>{{#(plan.title)}} - #{displayAmount}</h4>
    <span class='payment-type'>#{statusNotice}</span>
    <p>#{dateNotice}</p>
    """