class PlanUpgradeForm extends JView

  setPlans: (plans) ->
    @listController.instantiateListItems plans

  viewAppended: ->
    @listController = new KDListViewController
      itemClass: GroupPlanListItem

    super()

  pistachio: ->
    """
    this is the plan upgrade form:
    {{> @listController.getView()}}
    """