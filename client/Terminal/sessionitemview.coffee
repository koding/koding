class SessionItemView extends KDView

  constructor: (options, data) ->

    options.tagName = 'li'
    options.index  ?= 1
    options.partial = "Session #{options.index} <cite>x</cite>"

    super options, data


  click: (event)->

    {session, machine} = @getOptions()

    task = if $(event.target).is 'cite' \
           then "SessionRemoveRequested" else "SessionSelected"

    @getDelegate().emit task, { machine, session }

    no
