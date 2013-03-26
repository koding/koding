class CommonListHeader extends KDView

  constructor:(options = {}, data)->

    options.tagName  = "header"
    options.cssClass = "feeder-header clearfix"

    super options, data

  viewAppended:->

    @setPartial "<p>#{@getOptions().title}</p> <span></span>"
    @emit "ready"