class GroupProductListItem extends KDListItemView

  viewAppended: ->
    product = @getData()

    { planCode, code, soldAlone } = product

    planCode ?= code

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
      callback : => @emit 'BuyersReportRequested', @getData()

    @deleteButton = new KDButtonView
      title    : "Remove"
      callback : => @emit 'DeleteRequested', @getData()

    @editButton = new KDButtonView
      title    : "Edit"
      callback : => @emit 'EditRequested', @getData()

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