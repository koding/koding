class IntroTeamPlan extends JView
  unitPrices     =
    resourcePack : 20
    user         : 5

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "team-plan", options.cssClass
    super options, data

    @resourceQuantity = 10
    @userQuantity     = 10
    @total            = (@resourceQuantity * unitPrices.resourcePack) + (@userQuantity * unitPrices.user)

    @resourcePackSlider = new IntroPlanSelection
      title             : "Resource Pack"
      description       : """
        <span>1 Resource pack contains</span>
        <br/><cite>4x</cite>CPU
        <cite>2x</cite>GB RAM
        <cite>50</cite>GB Disk
        <br/><cite>10x</cite>Total VMs
        <cite>1x</cite>Always on VMs
        """
      unitPrice         : unitPrices.resourcePack
      slider            :
        minValue        : 1
        maxValue        : 250
        interval        : 5
        snapOnDrag      : yes
        handles         : [@resourceQuantity]
        width           : 319

    @resourcePackSlider.on "ValueChanged", (@resourceQuantity) => @updateContent()

    @userSlider         = new IntroPlanSelection
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
      callback : =>
        @emit "PlanSelected", "custom-plan", {
          @userQuantity
          @resourceQuantity
          planApi: KD.remote.api.JGroupPlan
          total  : @total * 100
        }

    @updateContent()

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
