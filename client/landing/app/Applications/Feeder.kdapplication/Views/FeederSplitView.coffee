class FeederSplitView extends ContentPageSplitBelowHeader

  constructor:(options = {})->

    options.sizes     = [139, null]
    options.minimums  = [10, null]
    options.resizable = no
    options.bind      = "mouseenter"

    super options
