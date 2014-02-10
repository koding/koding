class BreadcrumbView extends JView


  constructor : (options = {}, data) ->

    options.cssClass  = KD.utils.curry "pricing-breadcrumb hidden", options.cssClass

    super options, data

    @checkOutButton = new KDButtonView
      title     : "CHECK OUT"
      cssClass  : "checkout-button"
      style     : "small solid yellow"

    @planName       = new KDCustomHTMLView
      tagName   : "span"

    @planProducts   = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "products"

    @planPrice      = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "price"


  selectItem : (name) ->

    return  unless name

    @$('li').removeClass "active"
    @$("li.#{name}").addClass "active"


  showPlan : (plan, options) ->
    {title, feeUnit} = plan
    feeAmount = (options.total or plan.feeAmount) / 100

    @show()
    document.body.classList.add 'flow'
    @planName.updatePartial title
    @planPrice.updatePartial "$#{feeAmount}/#{feeUnit}"

    if 'custom-plan' in plan.tags
    then @setClass 'team'
    else @unsetClass 'team'

    {resourceQuantity, userQuantity} = options
    if userQuantity
      @planProducts.updatePartial "#{userQuantity}x User<br>#{resourceQuantity}x Resource Packs"

  pistachio : ->
    """
      <ul class='clearfix logged-#{if KD.isLoggedIn() then 'in' else 'out'}'>
        <li class='login active'>Login/Register</li>
        <li class='method'>Payment method</li>
        <li class='overview'>Overview</li>
        <li class='details hidden'>Group details</li>
        <li class='thanks'>Thank you</li>
      </ul>
      <section>
        <h4>Your plan</h4>
        {{> @planName }}
        {{> @planProducts }}
        {{> @planPrice }}
      </section>
    """
