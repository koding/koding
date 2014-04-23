class PricingPacksView extends KDView

  constructor: (options = {}, data) ->

    options.tagName  = 'section'
    options.cssClass = "packs"
    options.packs   ?= []

    super options, data

  viewAppended : ->
    @addSubView new KDHeaderView
      title     : 'Choose a Resource Pack that suits your needs and you are good to go.'
      type      : 'medium'
      cssClass  : 'general-title'

    @createPacks()

  createPacks : ->

    @packs    = @getOption 'packs'

    for pack, index in @packs

      @addSubView @packs[index].view = new ResourcePackView pack





