class PricingPacksView extends KDView
  constructor: (options = {}, data) ->
    options.tagName  = "section"
    options.cssClass = "packs"
    super options, data

  viewAppended: ->
    @addSubView new KDCustomHTMLView
      partial   : "Our pricing, your terms"
      tagName   : "h4"
      cssClass  : "pricing-heading"

    @addSubView new KDCustomHTMLView
      tagName   : 'p'
      cssClass  : 'pricing-description'
      partial   : "
        Get started for free or go right into high gear with one of our aid plans.
        Our simple pricing is designed to help you get the most out of your Koding experience.
        Trusted by your peers worldwide.
      "

    for options in @packs
      options.delegate = this
      @addSubView view = new ResourcePackView options
      @forwardEvent view, "PlanSelected"
