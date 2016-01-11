ContentPageSplitBelowHeader = require 'app/commonviews/contentpagesplitbelowheader'

module.exports = class FeederSplitView extends ContentPageSplitBelowHeader

  constructor:(options = {})->

    options.sizes     or= [139, null]
    options.minimums  or= [10, null]
    options.resizable  ?= no
    options.bind      or= "mouseenter"

    super options
