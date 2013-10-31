class GroupPlanListItem extends GroupProductListItem
  viewAppended: ->
    plan = @getData()

    @planView = new GroupProductView {}, plan

    @addProductsButton = new KDButtonView
      title    : "Add products"
      callback : => @emit 'AddProductsRequested', plan

    @quantitiesView = new KDView
      cssClass : 'formline button-field clearfix'

    for own planCode, qty of plan.quantities
      @quantitiesView.addSubView new GroupPlanProduct {}, { planCode, qty }

    super()

  pistachio:->
    """
    {{> @planView}}
    {{> @embedButton}}
    {{> @deleteButton}}
    {{> @clientsButton}}
    {{> @editButton}}
    {{> @addProductsButton}}
    {{> @quantitiesView}}
    {{> @embedView}}
    """
