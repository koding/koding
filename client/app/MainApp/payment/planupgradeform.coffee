class PlanUpgradeForm extends JView

  setPlans: (plans) ->
    @listController.instantiateListItems plans

  viewAppended: ->
    @listController = new KDListViewController
      itemClass: GroupPlanListItem

    @listView = @listController.getListView()

    @listView.on 'ItemWasAdded', (item) =>
      item.setControls new KDButtonView
        title     : 'Upgrade'
        callback  : =>
          @emit 'PlanSelected', item.getData()

    super()

  pistachio: ->
    """
    <h2>
      You must upgrade your plan:
    </h2>
    {{> @listView}}
    """