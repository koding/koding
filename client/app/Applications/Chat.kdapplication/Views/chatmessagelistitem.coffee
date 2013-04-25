class ChatMessageListItem extends KDListItemView

  constructor:(options = {},data)->

    options.cssClass = "message"
    options.tagName  = "li"
    super options, data

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """{{#(message)}}"""
