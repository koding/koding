class PlanAdminControlsView extends ProductAdminControlsView

  viewAppended: ->
    plan = @getData()

    @addProductsButton = new KDButtonView
      title    : "Add products"
      callback : => @emit 'AddProductsRequested', plan

    super()

  pistachio:->
    """
    {{> @embedButton}}
    {{> @deleteButton}}
    {{> @clientsButton}}
    {{> @editButton}}
    {{> @addProductsButton}}
    {{> @embedView}}
    """