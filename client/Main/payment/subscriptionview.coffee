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
            "Will renew on #{dateFormat renew}"
          when 'canceled'
            "Will be available till #{dateFormat expires}"
          when 'future'
            "Will become available on #{dateFormat startsAt}"
      else ''

    displayAmount = KD.utils.formatMoney feeAmount / 100

    """
      <h4>{{#(plan.title)}}</h4>
      <span class="price">#{displayAmount}</span>
      <p>#{dateNotice}</p>
    """
