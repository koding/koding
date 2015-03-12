kd = require 'kd'

module.exports = class KiteItem extends kd.ListItemView
  partial: ( { kite } )->
    "#{kite.name} on #{kite.hostname} with #{kite.id} ID"
