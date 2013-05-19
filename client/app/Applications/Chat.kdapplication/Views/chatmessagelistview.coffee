class ChatMessageListView extends KDListView

  constructor:(options = {}, data)->

    options.autoScroll = yes
    options.cssClass   = "chat-conversation"
    options.tagName    = "ul"

    super options, data
