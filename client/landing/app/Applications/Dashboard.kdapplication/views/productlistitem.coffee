class GroupProductListItem extends KDListItemView

  viewAppended: ->
    { planCode, soldAlone } = @getData()

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
      callback : =>
        product = @getData()
        product.fetchSubscriptions (err, subs)->
          if err
            subs = []
          new KDNotificationView
            title: "This product has #{subs.length} buyer(s)."

    @deleteButton = new KDButtonView
      title    : "Remove"
      callback : =>
        @confirmDelete =>
          @getDelegate().emit "DeleteItem", planCode

    JView::viewAppended.call this

  confirmDelete:(callback) ->
    deleteModal = new KDModalView
      title        : "Warning"
      content      : "<div class='modalformline'>Are you sure you want to delete this item?</div>"
      height       : "auto"
      overlay      : yes
      buttons      :
        Yes        :
          loader   :
            color  : "#ffffff"
            diameter : 16
          style    : "modal-clean-gray"
          callback : ->
            deleteModal.destroy()
            callback()

  pistachio:->
    product = @getData()

    planCode  = product.planCode
    title     = product.title
    price     = (product.amount / 100).toFixed(2)

    subscriptionType =
      if product.subscriptionType is 'single'
        "Single payment"
      else
        "Recurring payment"

    """
    <div class="product-item">
      #{title} $#{price} - #{subscriptionType}
      {{> @embedButton}}
      {{> @deleteButton}}
      {{> @clientsButton}}
      <br>
      {{> @embedView}}
    </div>
    <hr>
    """