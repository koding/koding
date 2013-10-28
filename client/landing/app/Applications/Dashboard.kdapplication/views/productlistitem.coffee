class GroupProductListItem extends KDListItemView

  viewAppended: ->
    { planCode, code, soldAlone } = @getData()

    planCode ?= code

    @embedView = new EmbedCodeView { planCode }

    @embedButton = new KDButtonView
      title    : "View Embed Code"
      callback : =>
        if @embedView.hasClass "hidden"
          @embedView.unsetClass "hidden"
        else
          @embedView.setClass "hidden"

    @embedButton.hide()  unless soldAlone

    @clientsButton = new KDButtonView
      title    : "View Buyers"
      callback : => @emit 'BuyersReportRequested', planCode

    @deleteButton = new KDButtonView
      title    : "Remove"
      callback : => @emit 'DeleteRequested', planCode

    JView::viewAppended.call this

  prepareData: ->
    product = @getData()

    title     = product.title
    price     = (product.amount / 100).toFixed(2)

    subscriptionType =
      if product.subscriptionType is 'single'
        "Single payment"
      else
        "Recurring payment"

    { title, price, subscriptionType }

  pistachio: ->
    { title, price, subscriptionType } = @prepareData()

    """
    <div class="product-item">
      #{title} $#{price} - #{subscriptionType}
      {{> @embedButton}}
      {{> @deleteButton}}
      {{> @clientsButton}}
      {{> @embedView}}
    </div>
    <hr>
    """