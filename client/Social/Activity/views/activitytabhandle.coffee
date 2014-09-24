class ActivityTabHandle extends KDTabHandleView

  constructor: (options, data) ->
    options.cssClass = KD.utils.curry 'filter', options.cssClass
    super options, data
