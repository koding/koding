class ActivityListItemView extends KDListItemView


  getActivityChildCssClass = -> 'system-message'


  constructor:(options = {},data)->

    options.type = "activity"

    super options, data


  viewAppended:->

    @addChildView @getData()


  addChildView:(data, callback=->)->

    return unless data?.bongo_

    @addSubView new StatusActivityItemView delegate : this, data

    callback()


  partial:-> ''


  hide:-> @setClass 'hidden-item'

  show:-> @unsetClass 'hidden-item'
