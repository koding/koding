class PageInbox extends KDView
  
  KD.registerPage "Inbox", PageInbox

  createCommons:->
    @addSubView header = new HeaderViewSection type : "big", title : "Inbox"

    # Common left pane 
    @commonInnerNavigation = new InboxInnerNavigation

    @commonInnerNavigation.registerListener 
      KDEventTypes : "CommonInnerNavigationListItemReceivedClick"
      listener     : @
      callback     : (pubInst, data)=>
        return if data.disabledForBeta
        {type,action} = data
        @showTab type
        if action is "change-tab"
          @showTab data.type
        else
          @sort data.type

    @inboxTabs = new KDTabView
      cssClass  : "inbox-tabview" 
    @inboxTabs.hideHandleContainer()

    inboxSplitView = @inboxSplitView = new ContentPageSplitBelowHeader
      views     : [@commonInnerNavigation,@inboxTabs]
      sizes     : [138,null]
      cssClass  : "inbox-main-split"
      resizable : no
    
    @addSubView inboxSplitView

    inboxSplitView._windowDidResize()
    

  createTabs:->
    @_tab_messages      = @createMessagesTab()
    @_tab_notifications = @createNotificationsTab()
    @inboxTabs.showPane @_tab_messages
    
  createMessagesTab:->
    @inboxTabs.addPane tab = new KDTabPaneView cssClass : "messages-tab"
    
    @inboxMessagesContainer = new KDTabView cssClass : "message-thread-tabs"
    @inboxMessagesContainer.hideHandleContainer()

    @inboxMessagesList = inboxMessagesList = new InboxMessagesList
      # lastToFirst : yes
      delegate    : @
      subItemClass  : InboxMessagesListItem
    inboxMessageBody = new KDView cssClass : "message-body-wrap"
    inboxMessageInputWrapper = new KDView cssClass : "input-wrapper"

    inboxMessageListController = new InboxMessageListController
      view          : inboxMessagesList

    tab.addSubView @newMessageBar = new InboxNewMessageBar 
      cssClass  : "new-message-bar clearfix"
      delegate  : @inboxMessagesContainer

    @newMessageBar.on "RefreshButtonClicked", =>
      inboxMessageListController.removeAllItems()
      inboxMessageListController.loadMessages()
    
    inboxMessageListController.loadMessages()
      

    messagesSplit = new SplitViewWithOlderSiblings
      sizes     : ["100%",null]
      views     : [inboxMessagesList,@inboxMessagesContainer]
      cssClass  : "messages-split" 
      resizable : yes
      minimums  : [150, null]

    tab.addSubView messagesSplit
    messagesSplit._windowDidResize()


    messagesSplit.didResizeBefore = no
    messagesSplit.listenTo
      KDEventTypes       : "PanelDidResize"
      listenedToInstance : @inboxSplitView
      callback           : ->
        messagesSplit._windowDidResize()
        unless messagesSplit.didResizeBefore
          messagesSplit.resizePanel "100%",0
    
    messagesSplit.listenTo
      KDEventTypes : "MessageIsSelected"
      listenedToInstance : @
      callback :->
        @resizePanel "33%",0 unless messagesSplit.didResizeBefore
        messagesSplit.didResizeBefore = yes
    
    inboxMessageInputWrapper.addSubView @messageInputElement = new KDHitEnterInputView
      type         : "textarea" 
      name         : "sendMessage"
      cssClass     : "sendMessageInput"
      placeholder  : "Just type and press enter.."
      callback     : ()=>
        reply = @messageInputElement.getValue()
        @messageInputElement.setValue ''
        @propagateEvent KDEventType: 'ReplyShouldBeSent', {message: @messageInputElement.getData(), reply}

    @listenTo 
      KDEventTypes       : "viewAppended"
      listenedToInstance : @messageInputElement
      callback           : messagesSplit._windowDidResize
    
    return tab

  createNotificationsTab:->
    @inboxTabs.addPane tab = new KDTabPaneView cssClass : "notifications-tab"

    inboxNotificationsController = new MessagesListController
      view            : inboxNotificationsList = new InboxMessagesList
        cssClass      : "inbox-list notifications"
        subItemClass  : NotificationListItem
    
    tab.addSubView inboxNotificationsController.getView()
    inboxNotificationsController.fetchNotificationTeasers (items)=>
      inboxNotificationsController.instantiateListItems items
    
    return tab

  createFriendsTab:->
  
  createChatTab:->
    
  showTab:(type)->
    mainView = @
    unless mainView["_tab_#{type}"]?
      mainView["_tab_#{type}"] = mainView["create#{type.capitalize()}Tab"]()
    else
      mainView.inboxTabs.showPane mainView["_tab_#{type}"]
    @commonInnerNavigation.selectNavTab type





















class MemberAutoCompleteItemView extends KDAutoCompleteListItemView
  constructor:(options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    super
    
    {userInput} = @getDelegate()
    
    @avatar = new AutoCompleteAvatarView {},data
    @profileLink = new AutoCompleteProfileTextView {userInput, shouldShowNick: yes},data
    # @nickLink = new AutoCompleteNickView {userInput},data
    
  pistachio:->
    """
      <span class='avatar'>{{> @avatar}}</span>
      {{> @profileLink}}
    """

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
    
    
  partial:()-> ''

class MemberAutoCompletedItemView extends KDAutoCompletedItem
  constructor:(options, data)->
    options.cssClass = "clearfix"
    super
    @avatar = new AutoCompleteAvatarView {size : width : 16, height : 16},data
    @profileText = new AutoCompleteProfileTextView {},data

  pistachio:->
    """
      <span class='avatar'>{{> @avatar}}</span>
      {{> @profileText}}
    """

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()
    
  partial:()-> ''
    
  

    

  
  
  
