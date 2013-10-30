class GroupPlanListItem extends GroupProductListItem
  viewAppended: ->
    @planView = new GroupProductView {}, @getData()

    super()

  pistachio:->
    """
    {{> @planView}}
    {{> @embedButton}}
    {{> @deleteButton}}
    {{> @clientsButton}}
    {{> @editButton}}
    {{> @embedView}}
    """