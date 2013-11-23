class SubscriptionUsageView extends KDView

  getGauges: ->
    { subscription, components } = @getOptions()

    { plan } = subscription

    componentsByPlanCode = components.reduce( (memo, component) ->
      memo[component.planCode] = component
      memo
    , {})

    usage = (Object.keys subscription.usage).map (key) ->
      usage =
        component : componentsByPlanCode[key]
        quota     : plan.quantities[key]
        usage     : subscription.usage[key]

      usage.usageRatio = usage.usage / usage.quota
      
      return usage

  createGaugeListController: ->
    controller = new KDListViewController
      itemClass: SubscriptionGaugeItem

    controller.instantiateListItems @getGauges()

    controller

  viewAppended: ->
    @setClass 'subscription-gauges'
    
    @gaugeListController = @createGaugeListController()

    @addSubView @gaugeListController.getListView()