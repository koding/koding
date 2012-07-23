class CommonListHeader extends KDView
  viewAppended:->
    @setClass "activityhead clearfix"
    @setPartial "<p>#{@getOptions().title}</p> <span></span>"
