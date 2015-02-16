kd = require 'kd'
ActivityContentDisplay = require './activitycontentdisplay'


module.exports = class ContentDisplayStatusUpdate extends ActivityContentDisplay

  constructor:(options = {}, data={})->

    options.tooltip or=
      title     : "Status Update"
      offset    : 3
      selector  : "span.type-icon"

    super options,data

    @activityItem = new StatusActivityItemView delegate: this, @getData()

    @activityItem.on 'ActivityIsDeleted', ->
      kd.singleton('router').back()

  pistachio:-> "{{> @activityItem}}"
