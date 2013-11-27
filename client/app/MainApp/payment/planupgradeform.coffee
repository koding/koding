class PlanUpgradeForm extends JView

  setPlans: (plans) ->
    @listController.instantiateListItems plans

    return this

  setCurrentSubscription: (subscription, forceUpgrade = no) ->
    lowerTier = yes

    for own code, view of @planViewsByCode

      if code is subscription.planCode
        view.activate?()
        view.disable?()
        lowerTier = no

      else if forceUpgrade and lowerTier
        view.disable?()
    
    @emit 'CurrentSubscriptionSet', subscription

    return this

  viewAppended: ->
    @listController = new KDListViewController
      itemClass: GroupPlanListItem

    @listView = @listController.getListView()

    @planViewsByCode = {}
    @listView.on 'ItemWasAdded', (item) =>
      plan = item.getData()

      @planViewsByCode[plan.planCode] = item
      
      item.setControls new KDButtonView
        title     : 'Upgrade'
        callback  : =>
          @emit 'PlanSelected', plan

    super()

  pistachio: ->
    """
    <h2>
      Upgrade your plan:
    </h2>
    {{> @listView}}
    """