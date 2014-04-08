class SessionItemView extends KDView

  constructor: (options, data) ->
    options.tagName = "li"
    options.index  ?= 1
    options.partial = "Session #{options.index}"

    super options, data


  click: ->
    {delegate, session, vm} = @getOptions()
    @delegate.emit "sessionSelected", {vm, session}




