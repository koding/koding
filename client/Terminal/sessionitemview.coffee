class SessionItemView extends KDView

  constructor: (options, data) ->
    options.tagName = "li"

    super options, data


  click: ->
    {delegate, session, vm} = @getOptions()
    @delegate.emit "sessionSelected", {vm, session}


  viewAppended: JView::viewAppended


  pistachio: ->
    {index} = @getOptions()
    "Terminal Screen Session #{index}"
