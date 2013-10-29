class GroupProductListItem extends KDListItemView

  viewAppended: ->
    product = @getData()

    { planCode, soldAlone } = product

    @productView = new GroupProductView {}, product

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
      callback : => @emit 'BuyersReportRequested', product

    @deleteButton = new KDButtonView
      title    : "Remove"
      callback : => @emit 'DeleteRequested', product

    @editButton = new KDButtonView
      title    : "Edit"
      callback : => @emit 'EditRequested', product

    JView::viewAppended.call this

  pistachio: ->
    """
    <div class="product-item">
      {{> @productView}}
      {{> @embedButton}}
      {{> @deleteButton}}
      {{> @clientsButton}}
      {{> @editButton}}
      {{> @embedView}}
    </div>
    <hr>
    """