class TeamPlan extends JView
  unitPrices     =
    resourcePack : 20
    user         : 5

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "team-plan", options.cssClass
    super options, data

    @resourceQuantity = 10
    @userQuantity     = 10
    @total            = (@resourceQuantity * unitPrices.resourcePack) + (@userQuantity * unitPrices.user)

    @resourcePackSlider = new PricingPlanSelection
      title             : "Resource Pack"
      unitPrice         : unitPrices.resourcePack
      amountSuffix      : "x"
      slider            :
        minValue        : 1
        maxValue        : 250
        interval        : 5
        snapOnDrag      : yes
        handles         : [@resourceQuantity]
        width           : 319

    @resourcePackSlider.on "ValueChanged", (@resourceQuantity) => @updateContent()

    @userSlider         = new PricingPlanSelection
      title             : "Team Size"
      unitPrice         : unitPrices.user
      slider            :
        minValue        : 5
        maxValue        : 500
        interval        : 10
        snapOnDrag      : yes
        handles         : [@userQuantity]
        width           : 319

    @userSlider.on "ValueChanged", (@userQuantity) => @updateContent()

    @summary = new KDCustomHTMLView cssClass: "plan-selection-box selected"
    @summary.addSubView @title  = new KDCustomHTMLView tagName: "h4"
    @summary.addSubView @price  = new KDCustomHTMLView tagName: "h5"
    @summary.addSubView @buyNow = new KDButtonView
      cssClass : "buy-now"
      style    : "solid green"
      title    : "BUY NOW"
      loader   : yes
      callback : =>
        @buyNow.showLoader()
        @emit "PlanSelected", "custom-plan", {
          @userQuantity
          @resourceQuantity
          planApi: KD.remote.api.JGroupPlan
          total  : @total * 100
        }

    @updateContent()

  resourcePackUnits =
    cpu             : 2
    ram             : 2
    disk            : 10
    alwaysOn        : 1
    totalVMs        : 2

  updateContent: ->
    @total = (@resourceQuantity * unitPrices.resourcePack) + (@userQuantity * unitPrices.user)
    @title.updatePartial "Resource Pack x #{@resourceQuantity}<br>for #{@userQuantity} People"
    @price.updatePartial "$#{@total}/Month"

    {cpu, ram, disk, totalVMs, alwaysOn} = resourcePackUnits
    @resourcePackSlider.description.updatePartial """
    <span>Resource pack contains</span>
    <cite>#{cpu * @resourceQuantity}x</cite>CPU
    <cite>#{ram * @resourceQuantity}x</cite>GB RAM
    <cite>#{disk * @resourceQuantity}</cite>GB Disk
    <cite>#{totalVMs * @resourceQuantity}x</cite>Total VMs
    <cite>#{alwaysOn * @resourceQuantity}x</cite>Always on VMs
    """

  viewAppended: ->
    super

    @resourcePackSlider.addSubView new KDCustomHTMLView
      tagName : "a"
      cssClass: "pricing-show-details"
      partial : "What is This?"
      click   : =>
        @emit "ShowHowItWorks"

  pistachio: ->
    """
    {{> @resourcePackSlider}}
    {{> @userSlider}}
    {{> @summary}}
    """
