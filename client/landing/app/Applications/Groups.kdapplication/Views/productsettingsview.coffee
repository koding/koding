class GroupProductSettingsView extends JView

  constructor:->
    super
    @setClass "payment-settings-view"
    group = @getData()
    
    @name = new KDInputView
      cssClass   : "product-title"
      placeholder: "Product name"
      
    @price = new KDInputView
      cssClass   : "product-price"
      placeholder: "0.00"

    @button = new KDButtonView
      cssClass   : "product-button"
      title      : "+"
      callback   : =>
        group.addPlan
          name  : __utils.slugify @name.getValue()
          price : @price.getValue()
          title : @name.getValue()
        , (err,plan)=>
          if err
            new KDNotificationView
              title: "Unable to create plan: #{err}"
          else
            @name.setValue ""
            @price.setValue ""
            @controller.loadItems()

    @controller = new GroupProductListController
      group     : group
      itemClass : GroupProductListItem

    @list = @controller.getListView()

    @controller.loadItems()

  pistachio:->
    """
    {{> this.button}}
    {{> this.name}}
    {{> this.price}}
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

    listView = @getDelegate()

    {code} = @getData()

    codeCheck  = """
                 KD.remote.api.JRecurlySubscription.checkUserSubscription '#{code}', (err, subscriptions)->
                   if not err and subscriptions.length > 0
                     console.log "User is subscribed to the plan."
                 """

    codeGet    = """..."""

    codeWidget = """@content = new KDButtonView
                    cssClass   : "clean-gray test-input"
                    title      : "Subscribed!"
                    callback   : ->

                    @payment = new PaymentWidget
                      planCode        : '#{code}'
                      contentCssClass : 'modal-clean-green'
                      content         : @content

                    @payment.on "subscribed", ->
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

    @deleteButton = new KDButtonView
      title: "-"
 
  viewAppended: JView::viewAppended

  pistachio:->
    plan = @getData()

    code  = plan.code
    title = plan.title
    price = plan.feeMonthly / 100

    """
    <div class="product-item">
      #{title} $#{price.toFixed(2)}
      {{> @embedButton}}
      {{> @deleteButton}}
      {{> @clientsButton}}
      <br>
      {{> @embedView}}
    </div>
    """