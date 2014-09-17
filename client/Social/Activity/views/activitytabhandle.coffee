class ActivityTabHandle extends KDTabHandleView

  constructor: (options, data) ->
    options.cssClass = KD.utils.curry 'filter', options.cssClass

    console.log hidden: options.hidden
    console.trace()

    super options, data
