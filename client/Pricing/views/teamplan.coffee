class TeamPlan extends JView
  unitPrices     =
    resourcePack : 20
    user         : 5

  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "team-plan", options.cssClass
    options.tagName  = 'section'
    super options, data

    @resourceQuantity = 10
    @userQuantity     = 10
    @total            = (@resourceQuantity * unitPrices.resourcePack) + (@userQuantity * unitPrices.user)

    @sectionTitle    = new KDHeaderView
      type      : 'medium'
      cssClass  : 'general-title'
      title     : 'For large teams, here you can scale your resource pack
      alongside your team size'

    @slidersContainer   = new KDView
      cssClass          : 'sliders-container'

    @summary = new KDCustomHTMLView cssClass: "resource-pack red"
    @summary.addSubView @title  = new KDHeaderView
      type      : 'medium'
      cssClass  : 'pack-title'
      title     : "<cite>#{@resourceQuantity}x</cite>Resource Pack"

    @summary.addSubView @buyNow = new KDButtonView
      style     : 'pack-buy-button'
      icon      : yes
      title     : "BUY NOW"
      loader    : yes
      callback  : =>
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

  createSliders : ->
    sliderWidth = @slidersContainer.getWidth() - 120

    @slidersContainer.addSubView @resourcePackSlider = new PricingPlanSelection
      title             : "Resource Pack"
      unitPrice         : unitPrices.resourcePack
      amountSuffix      : "x"
      slider            :
        minValue        : 1
        maxValue        : 250
        interval        : 5
        snapOnDrag      : yes
        handles         : [@resourceQuantity]
        width           : sliderWidth
        drawOpposite    : yes

    @resourcePackSlider.on "ValueChanged", (@resourceQuantity) => @updateContent()

    @slidersContainer.addSubView @userSlider = new PricingPlanSelection
      title             : "Team Size"
      unitPrice         : unitPrices.user
      slider            :
        minValue        : 5
        maxValue        : 500
        interval        : 10
        snapOnDrag      : yes
        handles         : [@userQuantity]
        width           : sliderWidth
        drawOpposite    : yes

    @userSlider.on "ValueChanged", (@userQuantity) => @updateContent()

  updateContent: ->
    @total = (@resourceQuantity * unitPrices.resourcePack) + (@userQuantity * unitPrices.user)
    @title.updateTitle "<cite>#{@resourceQuantity}x</cite>Resource Pack"
    @buyNow.setTitle "<cite>$#{@total}</cite>BUY NOW"

  viewAppended: ->
    @parent.once "PaneDidShow", @bound 'createSliders'

    super

  pistachio: ->
    """
    {{> @sectionTitle}}
    <div class='custom-plan-container clearfix'>
      {{> @slidersContainer}}
      {{> @summary}}
    </div>
    """
