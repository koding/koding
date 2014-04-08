class SessionItemView extends KDView

  constructor: (options, data) ->

    options.tagName = 'li'
    options.index  ?= 1
    options.partial = "Session #{options.index}"

    super options, data


  click: ->

    {session, vm} = @getOptions()
    @getDelegate().emit "sessionSelected", {vm, session}

    no
