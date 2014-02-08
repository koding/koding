class DeveloperPlan extends JView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "developer-plan", options.cssClass

    super options, data

    @planIndex = 0

    @plans = [
      { cpu: 1, ram: 1, disk: "50 GB" , alwaysOn: 1, price: 19 }
      { cpu: 2, ram: 2, disk: "100 GB", alwaysOn: 2, price: 39 , discount:  4, vm: 1 }
      { cpu: 3, ram: 3, disk: "150 GB", alwaysOn: 3, price: 59 , discount:  8, vm: 2 }
      { cpu: 4, ram: 4, disk: "200 GB", alwaysOn: 4, price: 79 , discount: 12, vm: 3 }
      { cpu: 5, ram: 5, disk: "250 GB", alwaysOn: 5, price: 99 , discount: 16, vm: 4 }
    ]

    @slider        = new PricingPlanSelection
      title          : "Resource Pack"
      description    : "1x Resource pack contains 1 GB RAM 1x CPU, 1 GB RAM, 50 GB Disk, 2 TB Transfer, 5 total VMs and we shut it off after an hour for obvious reasons"
      unitPrice      : 20
      hidePrice      : yes
      slider         :
        minValue     : 0
        maxValue     : @plans.length
        interval     : 1
        initial      : 1
        snapOnDrag   : yes
        handles      : [1]
        width        : 715
        drawOpposite : yes

    @slider.on "ValueChanged", (index)=>
      @planIndex = Math.max index, 0
      @updateContent()

    @summary = new KDCustomHTMLView cssClass: "plan-selection-box selected"
    @summary.addSubView @title     = new KDCustomHTMLView tagName: "h4"
    @summary.addSubView @price     = new KDCustomHTMLView tagName: "h5"
    # @summary.addSubView @promotion = new KDCustomHTMLView tagName: "p", cssClass: "description"
    @summary.addSubView @buyNow    = new KDButtonView
      cssClass : "buy-now"
      style    : "solid green"
      title    : "BUY NOW"
      callback : =>
        { paymentController, router } = KD.singletons
        if @planIndex is 0
          return router.handleRoute '/Register'

        paymentController.fetchSubscriptionsWithPlans tags: $in: "vm", (err, subscriptions) =>
          return KD.showError err  if err
          @emit "CurrentSubscriptionSet", subscriptions.first  if subscriptions.length
          @emit "PlanSelected", "rp#{@planIndex + 1}", planApi: KD.remote.api.JResourcePlan

    @updateContent()

  updateContent: (index = @planIndex)->

    if index is 0
      title = 'Free Account'
      desc  = 'Good for development'
      @buyNow.setTitle 'SIGN UP'
    else
      title = "#{index}x Resource Pack"
      desc  = "$#{@plans[index-1].price}/Month"
      @buyNow.setTitle 'BUY NOW'

    @title.updatePartial title
    @price.updatePartial desc

    # plan = @plans[index-1]
    # {discount, vm} = plan

    # @promotion.updatePartial if discount and vm
    # then "TREAT: $#{discount} OFF OR #{vm} FREE VM#{if vm > 1 then 's' else ''}"
    # else ""

  pistachio: ->
    """
    {{> @slider}}
    {{> @summary}}
    """
