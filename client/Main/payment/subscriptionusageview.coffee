class SubscriptionUsageView extends KDView

  getGauges: ->
    { subscription, components } = @getOptions()

    { plan } = subscription

    componentsByPlanCode = components.reduce( (memo, component) ->
      memo[component.planCode] = component
      memo
    , {})

    usage = (Object.keys subscription.quantities).map (key) ->
      usage =
        component : componentsByPlanCode[key]
        quota     : subscription.quantities[key]
        usage     : subscription.usage[key]

      usage.usage ?= 0
      usage.usageRatio = usage.usage / usage.quota

      if isNaN usage.usageRatio then usage.usageRatio = 0

      return usage

  createGaugeListController: ->

    controller = new KDListViewController
      itemClass: SubscriptionGaugeItem

    items = @getGauges()
    controller.instantiateListItems items
    KD.getSingleton("vmController").on 'VMListChanged', => 
      items = @getGauges()
      controller.removeAllItems()
      controller.instantiateListItems items

    controller


  viewAppended: ->

    @setClass 'subscription-gauges'

    title = if 'custom-plan' in @getOption('subscription').tags
    then 'Group resources'
    else 'Your resource packs'

    @addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'title'
      partial  : title

    @gaugeListController = @createGaugeListController()
    @addSubView @gaugeListController.getListView()