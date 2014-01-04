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


  show:(callback)->

    @getData().fetchTeaser? (err, teaser)=>
      if teaser
        @addChildView teaser, => @slideIn()


  slideIn:(callback=noop)->

    @unsetClass 'hidden-item'
    callback()


  slideOut:(callback=noop)->

    @setClass 'hidden-item'
    callback()
