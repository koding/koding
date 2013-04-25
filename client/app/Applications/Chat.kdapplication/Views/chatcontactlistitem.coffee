class ChatContactListItem extends KDListItemView

  constructor:(options = {},data)->

    options.tagName   = "li"
    options.cssClass  = "person"
    super options, data

    @title = new ChatContactListItemTitle null, data
    @title.on 'click', @bound 'toggleConversation'

    @setDragHandlers()

  setDragHandlers:->

    @on 'DragStarted', (e, state)->
      @conversationWasOpen = @conversation.isVisible()
      @_dragStarted = yes

    @on 'DragInAction', _.throttle (x, y)->
      if y isnt 0 and @_dragStarted
        @conversation.collapse()
        @setClass 'ondrag'
    , 300

    @on 'DragFinished', (event)->

      @unsetClass 'ondrag'
      @_dragStarted = no

      height = $(event.target).closest('.kdlistitemview').height() or 33
      distance = Math.round(@dragState.position.relative.y / height)

      unless distance is 0
        itemIndex = @getDelegate().getItemIndex @
        newIndex  = itemIndex + distance
        @getDelegate().emit 'moveToIndexRequested', @, newIndex

      @setEmptyDragState yes
      @conversation.expand() if @conversationWasOpen

    @setDraggable
      handle : @title
      axis   : "y"

  toggleConversation:->
    @conversation.toggle()
    @conversation.takeFocus() if @conversation.isVisible()

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

    @conversation = new ChatConversationWidget @
    @conversation.on 'click', @conversation.bound 'takeFocus'

    @conversation.messageInput.on 'moveUpRequested', =>
      itemIndex = @getDelegate().getItemIndex @
      @getDelegate().emit 'moveToIndexRequested', @, itemIndex - 1
      @conversation.messageInput.setFocus()

    @conversation.messageInput.on 'moveDownRequested', =>
      itemIndex = @getDelegate().getItemIndex @
      @getDelegate().emit 'moveToIndexRequested', @, itemIndex + 1
      @conversation.messageInput.setFocus()

    @conversationWasOpen = no
    @addSubView @conversation

  pistachio:->
    """{{> @title}}"""
