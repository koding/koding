class IntroductionTooltip extends KDTooltip

  constructor: (options = {}, data) ->

    unless options.view
      if options.partial
        options.view = new KDView
          partial: options.partial

    super options, data

  @findParentInstance: ->
    parent = null
    for instance of KD.instances
      if instance.getOptions().introId is @getOptions().introId
        parent = instance
    return parent