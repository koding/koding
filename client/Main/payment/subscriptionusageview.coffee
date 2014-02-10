class SubscriptionUsageView extends KDView
  getProductList: ->
    subscription = @getData()
    {plan}       = subscription

    list = []
    list.push {productKey, subscription} for own productKey of plan.quantities
    return list

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
    controller.instantiateListItems @getProductList()
    @addSubView controller.getView()
