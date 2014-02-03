class IntroDeveloperPlan extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "developer-plan", options.cssClass
    super options, data

    @plans = [
      {cpu: 1, ram: 1, disk: "50 GB" , alwaysOn: 1, price: 20},
      {cpu: 2, ram: 2, disk: "100 GB", alwaysOn: 2, price: 40 , discount:  4, vm: 1},
      {cpu: 3, ram: 3, disk: "150 GB", alwaysOn: 3, price: 60 , discount:  8, vm: 2},
      {cpu: 4, ram: 4, disk: "200 GB", alwaysOn: 4, price: 80 , discount: 12, vm: 3},
      {cpu: 5, ram: 5, disk: "250 GB", alwaysOn: 5, price: 100, discount: 16, vm: 4}
    ]

    @planIndex = 0

    @slider        = new IntroPricingPlanSelection
      title        : "Resource Pack"
      description  : "1x Resource pack contains 1 GB RAM 1x CPU, 1 GB RAM, 50 GB Disk, 2 TB Transfer, 5 total VMs and we shut it off after an hour for obvious reasons"
      unitPrice    : 20
      slider       :
        minValue   : 1
        maxValue   : @plans.length
        interval   : 1
        initial    : 1
        snapOnDrag : yes
        handles    : [1]
        width      : 685

    @slider.on "ValueChanged", (index) =>
      @planIndex = Math.max index - 1, 0
      @updateContent()

    @summary = new KDCustomHTMLView cssClass: "plan-selection-box selected"
    @summary.addSubView @title     = new KDCustomHTMLView tagName: "h4"
    @summary.addSubView @price     = new KDCustomHTMLView tagName: "h5"
    @summary.addSubView @promotion = new KDCustomHTMLView tagName: "p", cssClass: "description"
    @summary.addSubView @buyNow    = new KDButtonView
      cssClass : "solid buy-now"
      title    : "BUY NOW"
      callback : =>
        @emit "PlanSelected", "rp#{@planIndex + 1}", planApi: KD.remote.api.JResourcePlan

    @updateContent()

  updateContent: ->
    @title.updatePartial "#{@planIndex + 1}x Resource Pack"
    @price.updatePartial "$#{@plans[@planIndex].price}/Month"

    plan = @plans[@planIndex]
    {discount, vm} = plan

    @promotion.updatePartial if discount and vm
    then "TREAT: $#{discount} OFF OR #{vm} FREE VM#{if vm > 1 then 's' else ''}"
    else ""

  pistachio: ->
    """
    {{> @slider}}
    {{> @summary}}
    """
