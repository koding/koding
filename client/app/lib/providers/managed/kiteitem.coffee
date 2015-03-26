kd = require 'kd'

module.exports = class KiteItem extends kd.ListItemView

  constructor: (options = {}, data = {})->
    options.cssClass = kd.utils.curry 'kite-item', options.cssClass
    super options, data

  partial: (data)->

    if @getOption 'isHeader'

      @setClass 'header'

      ip       = "IP Address"
      hostname = "Hostname"
      name     = "Kite Name"
      version  = "Version"
      id       = "Kite ID"
      inUse    = "Machine"

    else

      {kite, ipAddress, url, machine} = data
      {name, version, id, hostname} = kite

      id = (id.split '-').first
      ip = "<a href='#{url}' target=_blank>#{ipAddress}</a>"
      inUse = if machine?
      then "#{machine.label}"
      else '--'

    "
      <div>#{ip}</div>
      <div>#{hostname}</div>
      <div>#{name}</div>
      <div>#{version}</div>
      <div>#{id}</div>
      <div>#{inUse}</div>
    "
