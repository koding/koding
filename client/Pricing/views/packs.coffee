class PricingPacksView extends KDView
  constructor: (options = {}, data) ->
    options.tagName  = "section"
    options.cssClass = "packs"
    super options, data

  viewAppended: ->
    @addSubView new KDHeaderView
      title     : "Choose a Resource Pack that suits your needs and you are good to go."
      type      : "medium"
      cssClass  : "general-title"

    for options in @packs
      options.delegate = this
      @addSubView view = new ResourcePackView options
      @forwardEvent view, "PlanSelected"
