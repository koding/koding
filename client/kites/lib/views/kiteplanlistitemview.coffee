kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDListItemView = kd.ListItemView
showError = require 'app/util/showError'
formatMoney = require 'app/util/formatMoney'


module.exports = class KitePlanListItemView extends KDListItemView

  constructor: (options = {}, data) ->

    options.type = kd.utils.curry "kite-product"

    super options, data

    @subscribeButton = new KDButtonView
      title          : "Subscribe"
      cssClass       : "solid green small subscribe-button"
      callback       : @bound "selectPlan"

  selectPlan: ->
    @getDelegate().emit "PlanSelected", @getData()

  unsubscribe: ->
    @subscription.cancel (err) =>
      return showError err  if err
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
        <p class="price">#{formatMoney feeAmount / 100}/#{feeUnit}</p>
      """

    @addSubView @subscribeButton

    kd.singleton("paymentController").fetchSubscriptionsWithPlans
      tags: $in: tags
    , (err, subscriptions) =>
      for subscription in subscriptions
        if subscription.plan.getId() is data.getId()
          @subscription = subscription
          @subscribeButton.setTitle "Unsubscribe"
          @subscribeButton.setCallback @bound "unsubscribe"
