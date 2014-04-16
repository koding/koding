class KitePlanListItemView extends KDListItemView

  constructor: (options = {}, data) ->

    options.type = KD.utils.curry "kite-product"

    super options, data

    @subscribeButton = new KDButtonView
      title          : "Subscribe"
      cssClass       : "solid green small subscribe-button"
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
        <p class="title">#{title}</p>
        <p class="desc">#{description}</p>
        <p class="price">#{KD.utils.formatMoney feeAmount / 100}/#{feeUnit}</p>
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
