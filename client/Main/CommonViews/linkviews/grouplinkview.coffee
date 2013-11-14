class GroupLinkView extends LinkView

  constructor: (options = {}, data) ->
    super options, data
    @setClass "profile"

  render:->
    {slug} = @getData()
    @setAttribute "href", "/#{slug}"
    @setAttribute "target", "_blank"
    super

  pistachio:->
    super "{{#(title)}}"

  click:-> #super has @utils.stopDOMEvent
