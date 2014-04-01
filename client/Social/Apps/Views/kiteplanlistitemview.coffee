class KitePlanListItemView extends KDListItemView
  constructor: (options = {}, data) ->
    options.type = KD.utils.curry "kite-product"
    super options, data

    @subscribeButton = new KDButtonView
      title          : "Subscribe"
      callback       : @bound "selectPlan"

  selectPlan: ->
    @getDelegate().emit "PlanSelected", @getData()

  unsubscribe: ->
    @subscription.cancel (err) =>
      return KD.showError err  if err
      @subscribeButton.setTitle "Subscribe"
      @subscribeButton.setCallback @bound "selectPlan"

  partial: -> ""

  viewAppended: ->
    super

    data = @getData()
    {title, description, feeAmount, feeUnit, tags} = data

    @addSubView new KDCustomHTMLView
      partial: """
        #{title}
        #{description}
        #{feeAmount}
        #{feeUnit}
      """

    @addSubView @subscribeButton

    KD.singleton("paymentController").fetchSubscriptionsWithPlans
      tags: $in: tags
    , (err, subscriptions) =>
      for subscription in subscriptions
        if subscription.plan.getId() is data.getId()
          @subscription = subscription
          @subscribeButton.setTitle "Unsubscribe"
          @subscribeButton.setCallback @bound "unsubscribe"
