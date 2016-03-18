kd = require 'kd'
KDListView = kd.ListView


module.exports = class CommonInnerNavigationList extends KDListView

  constructor : (options = {}, data) ->

    options.tagName or= 'nav'
    options.type      = 'inner-nav'

    super options, data
