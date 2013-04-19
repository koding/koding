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
  loadItems:(callback)->
    super

    @me.fetchFollowersWithRelationship {}, {}, (err, accounts)=>
      @instantiateListItems accounts unless err

class ChatContactListView extends KDListView

  constructor:(options = {}, data)->

    options.cssClass  = "chat-list"
    options.tagName   = "ul"

    super options, data

class ChatContactListItem extends KDListItemView

  constructor:(options = {},data)->

    options.tagName  = "li"
    options.cssClass = "person"
    super options, data

    @title = new ChatContactListItemTitle null, data
    @title.on 'click', @bound 'createConversation'

  createConversation:->
    unless @conversation
      @conversation = new ChatContactListConversationWidget
      @conversation.on 'click', @conversation.bound 'takeFocus'
      @addSubView @conversation
    else
      @conversation.$().toggleClass 'ready'
      @conversation.takeFocus()

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

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

    @conversationList = new ChatConversationListView
      itemClass : ChatConversationListItem

    @conversationController = new ChatConversationListController
      view : @conversationList

    KD.utils.defer =>
      @setClass 'ready'
      @takeFocus()

  takeFocus:-> @messageInput.setFocus()

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
      type         : "text"
      placeholder  : "Type your message..."
      callback     : ->
        @emit 'messageSent', @getValue()
        @setValue ''
        @setFocus()
