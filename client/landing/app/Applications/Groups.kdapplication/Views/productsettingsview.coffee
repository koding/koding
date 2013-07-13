class GroupProductSettingsView extends JView

  constructor:->
    super
    @setClass "payment-settings-view"
    group = @getData()
    
    @addName = new KDInputView
      cssClass   : "product-title"
      placeholder: "Product name"
      
    @addPrice = new KDInputView
      cssClass   : "product-price"
      placeholder: "0.00"

    @addType = new KDSelectBox
      defaultValue  : "single"
      selectOptions : [
        { title : "Single Payment"   , value : 'single'    }
        { title : "Recurring Payment", value : 'recurring' }
      ]

    @addButton = new KDButtonView
      cssClass   : "product-button"
      title      : "+"
      callback   : =>
        group.addProduct
          name  : __utils.slugify @addName.getValue()
          price : @addPrice.getValue()
          title : @addName.getValue()
          type  : @addType.getValue()
        , (err,plan)=>
          if err
            new KDNotificationView
              title: "Unable to create plan: #{err}"
          else
            @addName.setValue ""
            @addPrice.setValue ""
            @addType.setValue 'single'
            @controller.loadItems()

    @controller = new GroupProductListController
      group     : group
      itemClass : GroupProductListItem
    @controller.loadItems()        

    @list = @controller.getListView()
    @list.on "DeleteItem", (code)=>
      group.deleteProduct {code}, =>
        @controller.loadItems()

    @reloadButton = new KDButtonView
      cssClass   : "product-button"
      title      : "R"
      callback   : =>
        @controller.loadItems()

  pistachio:->
    """
    {{> this.addButton}}
    {{> this.addName}}
    {{> this.addType}}
    {{> this.addPrice}}
    <br>
    {{> this.reloadButton}}
    <br>
    {{> this.controller.getView()}}
    """
  viewAppended: ->
    @setTemplate do @pistachio


class GroupProductListController extends KDListViewController

  constructor:(options = {}, data)->
    @group = options.group
    super

  loadItems:(callback)->
    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

    KD.remote.api.JRecurlyPlan.getPlans 'groupplan', @group._id, (err,plans)=>
      if err or plans.length is 0
        @hideLazyLoader()
        @addCustomItem "This group has no products."
      else
        @hideLazyLoader()
        @instantiateListItems plans

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message


class GroupProductListItem extends KDListItemView
  constructor:(options,data)->
    super options, data

    {code} = @getData()

    codeCheck  = """
                 KD.remote.api.JRecurlySubscription.checkUserSubscription '#{code}', (err, subscriptions)->
                   if not err and subscriptions.length > 0
                     console.log "User is subscribed to the plan."
                 """

    codeGet    = """..."""

    codeWidget = """@content = new KDButtonView
                    cssClass   : "clean-gray test-input"
                    title      : "Subscribed! View Video"
                    callback   : ->
                      console.log "Open video..."

                    @payment = new PaymentWidget
                      planCode        : '#{code}'
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
        plan = @getData()
        plan.getSubscriptions (err, subs)->
          if err
            subs = []
          new KDNotificationView
            title: "This product has #{subs.length} buyer(s)."

    @deleteButton = new KDButtonView
      title    : "-"
      callback : =>
        @confirmDelete =>
          @getDelegate().emit "DeleteItem", code

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
    plan = @getData()

    code  = plan.code
    title = plan.title
    price = plan.feeMonthly / 100

    if plan.feeInterval is 9999
      type = "Single Payment"
    else
      type = "Recurring Payment"

    """
    <div class="product-item">
      #{title} $#{price.toFixed(2)} - #{type}
      {{> @embedButton}}
      {{> @deleteButton}}
      {{> @clientsButton}}
      <br>
      {{> @embedView}}
    </div>
    """