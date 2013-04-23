class DemosAppController extends AppController

  KD.registerAppClass @,
    name         : "Demos"
    route        : "Demos"
    hiddenHandle : yes

  constructor:(options = {}, data)->
    options.view    = new DemosMainView
      cssClass      : "content-page demos"
    options.appInfo =
      name          : "Demos"

    super options, data

  loadView:(mainView)->
    mainView.addSubView new KDHeaderView
      title : 'Demo App'

    chatListView = new ChatContactListView
      itemClass : ChatContactListItem

    chatController = new ChatContactListController
      view : chatListView

    chatController.loadItems()

    mainView.addSubView chatListView

class CommonChatController extends KDListViewController

  constructor:->
    super
    @me = KD.whoami()

  loadView:->
    super
    list = @getListView()
    @loadItems()

  loadItems:(callback)->
    @removeAllItems()
    @customItem?.destroy()
    @showLazyLoader no

  addCustomItem:(message)->
    @removeAllItems()
    @customItem?.destroy()
    @scrollView.addSubView @customItem = new KDCustomHTMLView
      cssClass : "no-item-found"
      partial  : message

class ChatContactListController extends CommonChatController

  constructor:->
    super
    @getListView().on 'moveToIndexRequested', @bound 'moveItemToIndex'

  loadItems:(callback)->
    super

    @me.fetchFollowersWithRelationship {}, {}, (err, accounts)=>
      @instantiateListItems accounts unless err

class ChatContactListView extends KDListView

  constructor:(options = {}, data)->

    options.cssClass  = "chat-list"
    options.tagName   = "ul"

    super options, data

  getItemIndex:(targetItem)->
    for item, index in @items
      return index if item is targetItem
    return -1

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
        distance = Math.round(y / 33)
        @conversation.collapse()
        @setClass 'ondrag'
    , 300

    @on 'DragFinished', (e)->
      @unsetClass 'ondrag'
      @_dragStarted = no
      distance = Math.round(@dragState.position.relative.y / 33)

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

    @conversation = new ChatContactListConversationWidget @
    @conversation.on 'click', @conversation.bound 'takeFocus'
    @conversationWasOpen = no
    @addSubView @conversation

  pistachio:->
    """{{> @title}}"""

class ChatContactListItemTitle extends JView

  constructor:(options = {},data)->
    options.cssClass = 'chat-contact-list-item-title'
    super

    @avatar = new AvatarView {
      size    : {width: 30, height: 30}
      origin  : data
    }

  pistachio:->
    """
      <div class='avatar-wrapper fl'>
        {{> @avatar}}
      </div>
      <div class='right-overflow'>
        <h3>{{#(profile.firstName)+' '+#(profile.lastName)}}</h3>
      </div>
    """

class ChatContactListConversationWidget extends JView

  constructor:(item)->
    options =
      cssClass : 'inline-conversation-widget'

    super options

    @messageInput = new ChatInputWidget
    @messageInput.on 'messageSent', (message)=>
      @conversationController.addItem {message}

    @messageInput.on 'goUpRequested', =>
      item.getDelegate().goUp item

    @messageInput.on 'goDownRequested', =>
      item.getDelegate().goDown item

    @conversationList = new ChatConversationListView
      itemClass : ChatConversationListItem

    @conversationController = new ChatConversationListController
      view : @conversationList

  toggle:->
    @toggleClass 'ready'

  collapse:->
    @unsetClass 'ready'

  expand:->
    @setClass 'ready'
    @takeFocus()

  isVisible:->
    @hasClass 'ready'

  takeFocus:->
    @messageInput.setFocus()

  pistachio:->
    """
      {{> @conversationList}}
      {{> @messageInput}}
    """

class ChatConversationListController extends CommonChatController

class ChatConversationListView extends KDListView

  constructor:(options = {}, data)->

    options.cssClass  = "chat-conversation"
    options.tagName   = "ul"

    super options, data

class ChatConversationListItem extends KDListItemView

  constructor:(options = {},data)->

    options.cssClass = "message"
    options.tagName  = "li"
    super options, data

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """{{#(message)}}"""

class ChatInputWidget extends KDHitEnterInputView

  constructor:->
    super
      type              : "text"
      placeholder       : "Type your message..."
      keyup             :
        "up"            : (e) => @emit 'goUpRequested'
        "down"          : (e) => @emit 'goDownRequested'
        # "super+up"      : (e) =>
        #   e.preventDefault()
        #   log 'move prev'
        # "super+down"    : (e) =>
        #   e.preventDefault()
        #   log 'move next'
      callback          : ->
        @emit 'messageSent', @getValue()
        @setValue ''
        @setFocus()

