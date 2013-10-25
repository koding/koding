class GroupProductListItem extends KDListItemView

  constructor:(options,data)->
    super options, data

    { planCode } = @getData()

    codeCheck =
      """
      KD.remote.api.JPaymentSubscription.checkUserSubscription '#{planCode}', (err, subscriptions)->
        if not err and subscriptions.length > 0
          console.log "User is subscribed to the plan."
      """

    codeGet =
      """
      KD.remote.api.JPaymentPlan.fetchPlanByCode '#{planCode}', (err, plan)->
        if not err and plan
          plan.fetchSubscriptions (err, subs)->
            console.log "Subscribers:", subs
      """

    codeWidget =
      """
      @content = new KDButtonView
        cssClass   : "clean-gray test-input"
        title      : "Subscribed! View Video"
        callback   : ->
          console.log "Open video..."

      @payment = new PaymentWidget
        planCode        : '#{planCode}'
        contentCssClass : 'modal-clean-green'
        content         : @content

      @payment.on "subscribed", ->
        console.log "User is subscribed."
      """

    @embedButton = new KDButtonView
      title    : "View Embed Code"
      callback : =>
        if @embedView.hasClass "hidden"
          @embedView.unsetClass "hidden"
        else
          @embedView.setClass "hidden"

    @embedView = new KDTabView
      cssClass             : "hidden product-embed"
      hideHandleCloseIcons : yes
      paneData             : [
        { name : "Check Subscription", partial: "<pre>#{codeCheck}</pre>" }
        { name : "Get Subscribers",    partial: "<pre>#{codeGet}</pre>" }
        { name : "Subscribe Widget",   partial: "<pre>#{codeWidget}</pre>" }
      ]

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

  viewAppended: JView::viewAppended

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