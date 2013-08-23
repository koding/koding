class TagLinkView extends LinkView

  constructor:(options = {}, data)->
    options.expandable ?= yes
    options.clickable  ?= yes
    if not options.expandable and data?.title.length > 16
      options.tooltip =
        title     : data.title
        placement : "above"
        delayIn   : 120
    super options, data

    data.on? "TagIsDeleted", => @destroy()

    @setClass "ttag expandable"
    @unsetClass "expandable" unless options.expandable

    @on "viewAppended", => @tooltip?.setPosition()

  pistachio:->
    super "{{#(title)}}"

#  click:(event)->
#    event?.stopPropagation()
#    event?.preventDefault()
#    return unless @getOptions().clickable
#    @emit 'LinkClicked'