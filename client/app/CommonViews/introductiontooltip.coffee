class IntroductionTooltip extends KDTooltip

  constructor: (options = {}, data) ->

    if not options.view and options.partial
      options.view = new KDView
        partial: options.partial

    super options, data