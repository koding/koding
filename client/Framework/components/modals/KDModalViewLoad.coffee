class KDModalViewLoad extends KDModalView
  constructor:(options)->
    super options
    options.onLoad?()
    @onBeforeDestroy = options.onBeforeDestroy if options.onBeforeDestroy?

  destroy:()->
    @onBeforeDestroy?()
    super
