class ContentDisplayStatusUpdate extends ActivityContentDisplay

  constructor:(options = {}, data={})->

    options.tooltip or=
      title     : "Status Update"
      offset    : 3
      selector  : "span.type-icon"

    super options,data

    @activityItem = new StatusActivityItemView delegate: this, @getData()

    @activityItem.on 'ActivityIsDeleted', ->
      KD.singleton('router').back()

  pistachio:-> "{{> @activityItem}}"
