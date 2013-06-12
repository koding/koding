class ChatMessageListItem extends KDListItemView

  constructor:(options = {},data)->

    options.cssClass = KD.utils.curryCssClass "message", data.cssClass
    options.tagName  = "li"
    super options, data

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """<strong>{{#(sender)}}</strong>: {{#(message)}}"""
