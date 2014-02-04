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
      description       : "1x Resource pack contains 1 GB RAM 1x CPU, 1 GB RAM, 50 GB Disk, 2 TB Transfer, 5 total VMs and we shut it off after an hour for obvious reasons"
      unitPrice         : unitPrices.resourcePack
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
      cssClass : "solid buy-now"
      title    : "BUY NOW"
      callback : =>
        @emit "PlanSelected", "custom-plan", {
          @userQuantity
          @resourceQuantity
          planApi: KD.remote.api.JGroupPlan
          total  : @total * 100
        }

    @updateContent()

    payment = KD.singleton "paymentController"
    payment.fetchSubscriptionsWithPlans tags: $in: "custom-plan", (err, subscriptions) =>
      return KD.showError err  if err
      @emit "CurrentSubscriptionSet", subscriptions.first  if subscriptions.length

  updateContent: ->
    @total = (@resourceQuantity * unitPrices.resourcePack) + (@userQuantity * unitPrices.user)
    @title.updatePartial "#{@resourceQuantity}x Resource Pack<br>for #{@userQuantity} People"
    @price.updatePartial "$#{@total}/Month"

  pistachio: ->
    """
    {{> @resourcePackSlider}}
    {{> @userSlider}}
    {{> @summary}}
    """
