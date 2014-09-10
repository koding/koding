class PricingPacksView extends KDView
  constructor: (options = {}, data) ->
    options.tagName  = "section"
    options.cssClass = "packs"
    super options, data

  viewAppended: ->
    @addSubView new KDHeaderView
      title     : "Our pricing, your terms"
      type      : "medium"
      cssClass  : "general-title"

    for options in @packs
      options.delegate = this
      @addSubView view = new ResourcePackView options
      @forwardEvent view, "PlanSelected"
