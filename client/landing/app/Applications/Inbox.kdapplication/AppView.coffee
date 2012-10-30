class InboxView extends KDView

  createCommons:->
    @addSubView header = new HeaderViewSection type : "big", title : "Inbox"

    # Common left pane
    @commonInnerNavigation = new InboxInnerNavigation

    @commonInnerNavigation.on "NavItemReceivedClick", (data)=>
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

    @inboxSplitView = new ContentPageSplitBelowHeader
      views     : [@commonInnerNavigation, @inboxTabs]
      sizes     : [138, null]
      cssClass  : "inbox-main-split"
      resizable : no

    @addSubView @inboxSplitView

    @inboxSplitView._windowDidResize()

  createTabs:->
    @_tab_messages      = @createMessagesTab()
    @_tab_notifications = @createNotificationsTab()
    @inboxTabs.showPane @_tab_messages

  createMessagesTab:->
    @inboxTabs.addPane tab = new KDTabPaneView cssClass : "messages-tab"

    @inboxMessagesContainer = new KDTabView cssClass : "message-thread-tabs"
    @inboxMessagesContainer.hideHandleContainer()

    @inboxMessagesList = inboxMessagesList = new InboxMessagesList
      delegate          : @
      itemClass      : InboxMessagesListItem

    inboxMessageListController = new InboxMessageListController
      delegate          : @
      view              : inboxMessagesList

    # lazyLoadThreshold : .75
    # inboxMessageListController.registerListener
    #   KDEventTypes  : 'LazyLoadThresholdReached'
    #   listener      : @
    #   callback      : => log "asdfasdfasdfasdf"

    tab.addSubView @newMessageBar = new InboxNewMessageBar
      cssClass  : "new-message-bar clearfix"
      delegate  : @inboxMessagesContainer

    @newMessageBar.on "RefreshButtonClicked", =>
      inboxMessageListController.loadMessages =>
        @newMessageBar.refreshButton.hideLoader()

    @newMessageBar.disableMessageActionButtons()

    @messagesSplit = new SplitViewWithOlderSiblings
      sizes     : ["100%",null]
      views     : [inboxMessagesList, @inboxMessagesContainer]
      cssClass  : "messages-split"
      resizable : yes
      minimums  : [150, null]

    tab.addSubView @messagesSplit
    @messagesSplit._windowDidResize()

    @messagesSplit.didResizeBefore = no

    @on "MessageSelectedFromOutside", (item)=>
      @newMessageBar.enableMessageActionButtons()

      messageIsSelectable = =>
        {items} = inboxMessagesList
        return no if items.length is 0
        {_id} = item.getData()
        wasMessageInList = no
        items.forEach (message) =>
          if message.getData()?.getId?() is _id
            message.click()
            wasMessageInList = yes
        wasMessageInList

      if item
        if not messageIsSelectable()
          inboxMessageListController.loadMessages =>
            if not messageIsSelectable()
              @emit "MessageIsSelected", {item, event}
      else
        inboxMessageListController.loadMessages()

    return tab

  createNotificationsTab:->
    @inboxTabs.addPane tab = new KDTabPaneView cssClass : "notifications-tab"

    inboxNotificationsController = new MessagesListController
      view            : inboxNotificationsList = new InboxMessagesList
        cssClass      : "inbox-list notifications"
        itemClass     : NotificationListItem

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

    userInput = options.userInput or @getDelegate().userInput

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
