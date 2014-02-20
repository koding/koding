class SubscriptionUsageView extends KDView
  fetchProductList: (callback) ->
    subscription = @getData()
    {plan}       = subscription

    list = []

    options = targetOptions: selector: planCode: {$in: Object.keys plan.quantities}, tags: $in: ["vm"]
    plan.fetchProducts null, options, (err, products) ->
      return  if KD.showError err
      list.push {product, subscription} for product in products
      callback list

  viewAppended: ->
    @setClass 'subscription-gauges'

    title = if 'custom-plan' in @getData().tags
    then 'Group resources'
    else 'Your resource packs'

    @addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'title'
      partial  : title

    controller = new KDListViewController itemClass: SubscriptionGaugeItem
    @addSubView controller.getView()
    @fetchProductList (list) ->
      controller.instantiateListItems list
