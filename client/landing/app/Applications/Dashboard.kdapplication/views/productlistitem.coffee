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

    @editButton = new KDButtonView
      title    : "Edit"
      callback : => @emit 'EditRequested', @getData()

    JView::viewAppended.call this

  prepareData: ->
    product = @getData()

    title     = product.title
    price     = (product.feeAmount / 100).toFixed(2)

    subscriptionType =
      if product.subscriptionType is 'single'
      then "Single payment"
      else if product.feeUnit is 'months'
        switch product.feeInterval
          when 1        then "monthly"
          when 3        then "every 3 months"
          when 6        then "every 6 months"
          when 12       then "yearly"
          when 12 * 2   then "every 2 years"
          when 12 * 5   then "every 5 years"
          else               "every #{product.feeInterval} months"
      else '' # we don't support renewals by the day (yet)

    { title, price, subscriptionType }

  pistachio: ->
    { title, price, subscriptionType } = @prepareData()

    """
    <div class="product-item">
      #{title} — $#{price} #{subscriptionType}
      {{> @embedButton}}
      {{> @deleteButton}}
      {{> @clientsButton}}
      {{> @editButton}}
      {{> @embedView}}
    </div>
    <hr>
    """