class Pane extends KDView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry "pane", options.cssClass

    super options, data
