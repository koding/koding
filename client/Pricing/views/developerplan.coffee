class DeveloperPlan extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "developer-plan", options.cssClass
    super options, data

    @planIndex = 0

    @plans = [
      { cpu:  1,  ram:  1,  disk:   3, alwaysOn: 0, totalVMs:  1, price:  0 }
      { cpu:  2,  ram:  2,  disk:  10, alwaysOn: 1, totalVMs:  2, price: 19 }
      { cpu:  4,  ram:  4,  disk:  20, alwaysOn: 2, totalVMs:  4, price: 39 }
      { cpu:  6,  ram:  6,  disk:  40, alwaysOn: 3, totalVMs:  6, price: 59 }
      { cpu:  8,  ram:  8,  disk:  80, alwaysOn: 4, totalVMs:  8, price: 79 }
      { cpu: 10,  ram: 10,  disk: 100, alwaysOn: 5, totalVMs: 10, price: 99 }
    ]

    @slider          = new PricingPlanSelection
      title          : "Resource Pack"
      unitPrice      : 20
      hidePrice      : yes
      amountSuffix   : "x"
      slider         :
        minValue     : 0
        maxValue     : @plans.length - 1
        interval     : 1
        initial      : 1
        snapOnDrag   : no
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

        paymentController.fetchActiveSubscription ["vm"], (err, subscription) =>
          return KD.showError err  if err
          @emit "CurrentSubscriptionSet", subscription  if subscription
          @emit "PlanSelected", "rp#{@planIndex}",
            planApi: KD.remote.api.JResourcePlan
            resourceQuantity: @planIndex

    @updateContent()

  updateContent: (index = @planIndex)->
    if index is 0
      title = 'Free Account'
      desc  = '<cite>"free" as in "free beer"</cite>'
      @buyNow.setTitle 'SIGN UP'
    else
      title = "#{index}x Resource Pack"
      desc  = "$#{@plans[index].price}/Month"
      @buyNow.setTitle 'BUY NOW'

    @title.updatePartial title
    @price.updatePartial desc

    {cpu, ram, disk, totalVMs, alwaysOn} = @plans[index]
    @slider.description.updatePartial """
    <span>Resource pack contains</span>
    <cite>#{cpu}x</cite>CPU
    <cite>#{ram}x</cite>GB RAM
    <cite>#{disk}</cite>GB Disk
    <cite>#{totalVMs}x</cite>Total VMs
    <cite>#{alwaysOn}x</cite>Always on VMs
    """

    # plan = @plans[index]
    # {discount, vm} = plan

    # @promotion.updatePartial if discount and vm
    # then "TREAT: $#{discount} OFF OR #{vm} FREE VM#{if vm > 1 then 's' else ''}"
    # else ""

  viewAppended: ->
    super

    @slider.addSubView new KDCustomHTMLView
      tagName : "a"
      cssClass: "pricing-show-details"
      partial : "What is This?"
      click   : =>
        @emit "ShowHowItWorks"

  pistachio: ->
    """
    {{> @slider}}
    {{> @summary}}
    """
