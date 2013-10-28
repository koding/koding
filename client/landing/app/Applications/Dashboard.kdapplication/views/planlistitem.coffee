class GroupPlanListItem extends GroupProductListItem
  viewAppended: ->
    super()

  prepareData: ->
    product = @getData()

    title = product.title
    price = (product.feeAmount / 100).toFixed(2)

    subscriptionType =
      if product.subscriptionType is 'single'
        "Single payment"
      else
        "Recurring payment"

    { title, price, subscriptionType }

  pistachio:->
    { title, price, subscriptionType } = @prepareData()

    """
    One of these #{ title } #{ price } #{ subscriptionType }
    {{> @embedButton}}
    {{> @deleteButton}}
    {{> @clientsButton}}
    {{> @editButton}}
    {{> @embedView}}
    """