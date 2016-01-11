kd = require 'kd'
KDListViewController = kd.ListViewController
KDView = kd.View
KitePlanListItemView = require './kiteplanlistitemview'
showError = require 'app/util/showError'


module.exports = class KiteProductForm extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "kite-plan-product-form", options.cssClass

    super options, data

    @listController    = new KDListViewController
      itemChildClass   : KitePlanListItemView
      itemChildOptions :
        delegate       : this

  viewAppended: ->
    kite = @getData()
    kite.fetchPlans (err, plans) =>
      return showError err  if err

      payment = kd.singleton "paymentController"
      tags = []
      tags = tags.concat plan.tags for plan in plans
      tags = tags.filter (tag) -> yes  if tag isnt "kite"
      payment.fetchSubscriptionsWithPlans { tags }, (err, [subscription]) =>
        return showError err  if err
        @emit "CurrentSubscriptionSet", subscription  if subscription
        @listController.addItem item for item in plans
        @addSubView @listController.getView()
