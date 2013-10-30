class GroupPlanListItem extends GroupProductListItem
  viewAppended: ->
    plan = @getData()

    @planView = new GroupProductView {}, plan

    @addProductsButton = new KDButtonView
      title    : "Add products"
      callback : => @emit 'AddProductsRequested', plan

    super()

  pistachio:->
    """
    {{> @planView}}
    {{> @embedButton}}
    {{> @deleteButton}}
    {{> @clientsButton}}
    {{> @editButton}}
    {{> @addProductsButton}}
    {{> @embedView}}
    """