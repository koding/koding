class ChatContactListView extends KDListView

  constructor:(options = {}, data)->

    options.itemClass = ChatContactListItem
    options.cssClass  = "chat-list"
    options.tagName   = "ul"

    super options, data

  goUp:(item)->
    index = @getItemIndex item
    return unless index >= 0

    if index - 1 >= 0
      item.conversation.collapse()
      @items[index - 1].toggleConversation()

  goDown:(item)->
    index = @getItemIndex item
    return unless index >= 0

    if index + 1 < @items.length
      item.conversation.collapse()
      @items[index + 1].toggleConversation()
