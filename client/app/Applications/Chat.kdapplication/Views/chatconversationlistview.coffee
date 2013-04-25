class ChatConversationListView extends KDListView

  constructor:(options = {}, data)->

    options.cssClass  = "chat-conversation"
    options.tagName   = "ul"

    super options, data
