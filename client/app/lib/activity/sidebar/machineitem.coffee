kd = require 'kd'
KDListItemView = kd.ListItemView

module.exports = class MachineItem extends KDListItemView

  constructor: (options, data)->
    options.cssClass = 'machine-item'
    super options, data

  partial: (data)-> data.slug
