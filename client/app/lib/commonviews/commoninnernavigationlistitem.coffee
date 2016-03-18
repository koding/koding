kd = require 'kd'
KDListItemView = kd.ListItemView


module.exports = class CommonInnerNavigationListItem extends KDListItemView

  constructor : (options = {}, data) ->

    options.tagName  or= 'a'
    options.attributes = { href : data.slug or '#' }
    options.partial  or= data.title

    super options, data


  partial: -> ''
