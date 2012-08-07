class TagLinkView extends LinkView

  constructor:(options = {}, data)->
    options.expandable ?= no
    if not options.expandable and data?.title.length > 16
      options.tooltip =
        title     : data.title
        placement : "above"
        delayIn   : 120
        offset    : 1
    super options, data

    @setClass "ttag expandable"
    @unsetClass "expandable" unless options.expandable

  pistachio:->
    super "{{#(title)}}"

  click:->
    tag = @getData()
    appManager.tell "Topics", "createContentDisplay", tag
