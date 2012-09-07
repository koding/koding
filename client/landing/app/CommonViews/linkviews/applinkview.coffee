class AppLinkView extends LinkView

  constructor:(options = {}, data)->
    options.tooltip =
      title     : data.body
      placement : "above"
      delayIn   : 120
      offset    : 1
    super options, data

    # FIXME GG, Need to implement AppIsDeleted
    data.on? "AppIsDeleted", =>
      @destroy()

  pistachio:->
    super "{{#(title)}}"

  click:->
    app = @getData()
    appManager.tell "Apps", "createContentDisplay", app
