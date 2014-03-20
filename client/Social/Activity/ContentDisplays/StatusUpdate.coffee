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


  viewAppended:->

    cb       = JView::viewAppended.bind this
    activity = @getData()
    if /#\:JTag/.test activity.body
      activity.fetchTags (err, tags) =>
        activity.tags = tags  unless err
        cb()
    else cb()


  pistachio:-> "{{> @activityItem}}"
