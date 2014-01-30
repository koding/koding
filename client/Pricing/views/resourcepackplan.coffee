class ResourcePackPlan extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "resource-pack-plan", options.cssClass
    super options, data

    @plans = [
      {cpu: 1, ram: 1, disk: "50 GB" , alwaysOn: no , price: 20},
      {cpu: 2, ram: 2, disk: "100 GB", alwaysOn: yes, price: 40 , discount:  4, vm: 1},
      {cpu: 3, ram: 3, disk: "150 GB", alwaysOn: yes, price: 60 , discount:  8, vm: 2},
      {cpu: 4, ram: 4, disk: "200 GB", alwaysOn: yes, price: 80 , discount: 12, vm: 3},
      {cpu: 5, ram: 5, disk: "250 GB", alwaysOn: yes, price: 100, discount: 16, vm: 4}
    ]

    @planIndex = 0

    @slider       = new KDSliderBarView
      minValue    : 0
      maxValue    : @plans.length - 1
      interval    : 1
      snapOnDrag  : yes
      handles     : [@planIndex]
      drawBar     : no
      width       : 319 #712 for team

    @sliderTwo     = new KDSliderBarView
      minValue    : 0
      maxValue    : @plans.length - 1
      interval    : 1
      snapOnDrag  : yes
      handles     : [@planIndex]
      drawBar     : no
      width       : 319 #712 for team

    @toggle       = new KDMultipleChoice
      cssClass    : "pricing-toggle"
      labels      : ['DEVELOPER', 'TEAM']
      defaultValue: ['TEAM']
      multiple    : no
      callback    : ->

    @slider.on "ValueChanged", (handle) =>
      @planIndex = handle.getSnappedValue()
      @updateContent()

    @cpuQuantity  = new KDCustomHTMLView tagName: "span"
    @ramQuantity  = new KDCustomHTMLView tagName: "span"
    @diskQuantity = new KDCustomHTMLView tagName: "span"
    @alwaysOn     = new KDCustomHTMLView tagName: "span"
    @price        = new KDCustomHTMLView tagName: "span"
    @promotion    = new KDCustomHTMLView tagName: "span", cssClass: "promotion"
    @promotion.addSubView @discount = new KDCustomHTMLView tagName: "span"
    @promotion.addSubView @freeVM   = new KDCustomHTMLView tagName: "span"

    @updateContent()

    @buyNow    = new KDButtonView
      cssClass : 'solid buy-now'
      title    : 'BUY NOW'
      callback : =>
        @emit "PlanSelected", "rp#{@planIndex + 1}", planApi: KD.remote.api.JResourcePlan

  updateContent: ->
    @cpuQuantity.updatePartial @plans[@planIndex].cpu
    @ramQuantity.updatePartial @plans[@planIndex].ram
    @diskQuantity.updatePartial @plans[@planIndex].disk
    @alwaysOn.updatePartial if @plans[@planIndex].alwaysOn then "YES" else "NO"
    @price.updatePartial @plans[@planIndex].price

    {discount, vm} = @plans[@planIndex]
    if discount and vm
    then @promotion.updatePartial "$#{discount} OFF OR<br> #{vm} FREE VM"
    else @promotion.updatePartial ""

  pistachio: ->
    """
    <div class="inner-container">
      <header class="clearfix">
        <h2>Flexible Pricing for Developers and Teams</h2>
        <p>
          Either you are coding by yourself or coding with<br>
          your team, we got plans for you.
        </p>
        {{> @toggle}}
      </header>
      <div class="plan-selection team">

        <div class="plan-selection-box">
          <h4>Resource Packs <cite>3x</cite></h4>
          <h5>$30/Month</h5>
          {{> @slider}}
          <p class="description">
            1x Resource pack contains 1 GB RAM, 1x CPU, 1TB Disk
            and we shut it off after an hour for obvious reasons
          </p>
        </div>

        <div class="plan-selection-box">
          <h4>Resource Packs <cite>3x</cite></h4>
          <h5>$30/Month</h5>
          {{> @sliderTwo}}
          <p class="description">
            1x Resource pack contains 1 GB RAM, 1x CPU, 1TB Disk
            and we shut it off after an hour for obvious reasons
          </p>
        </div>

        <div class="plan-selection-box selected">
          <h4>3x Resource Packs</h4>
          <h5>$30/Month</h5>
          <p class="description">
            TREAT: $4 OFF OR 2 SHARED VMS
          </p>
          {{> @buyNow}}
        </div>
      </div>
    </div>
    """

# <div class="plan-selection">
#         <div class="resource-pack">
#           <h6>Resource Pack</h6>
#           <span class="resource cpu"><i></i> x{{> @cpuQuantity}}</span>
#           <span class="resource ram"><i></i> x{{> @ramQuantity}}</span>
#           <span class="resource disk"><i></i> x{{> @diskQuantity}}</span>
#           <span class="resource always-on"><i></i> {{> @alwaysOn}}</span>
#         </div>
#         <div class="sliderbar-outer-container">{{> @slider}}</div>
#         <div class="selected-plan">
#           <div class="price">
#             <cite>$</cite>{{> @price}}
#             <span class="period">/MONTH</span>
#           </div>
#           {{> @promotion}}
#           {{> @buyNow}}
#         </div>
#       </div>
