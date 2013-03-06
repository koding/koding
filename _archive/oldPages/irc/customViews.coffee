# class Chat_ViewStructure extends KDView
#   constructor:->
#     @account = @getSingleton("site").account
#     super
#
#   viewAppended:->
#     @addSubView @header       = new Chat_IrcTabPaneHeader()
#     @addSubView @content      = new KDScrollView cssClass : "list-holder"
#     @addSubView @footer       = new Chat_IrcTabPaneFooter()
#
# class Chat_IrcConnectionsView extends Chat_ViewStructure
#   viewAppended:->
#     super
#     @header.addSubView headerButtons = new Chat_HeaderConnections delegate : @
#
# class Chat_IrcConsoleView extends Chat_ViewStructure
#
#   _windowDidResize:()=>
#     @doResize()
#
#   viewAppended:->
#     super
#     @footer.destroy()
#     @listenWindowResize()
#
#     @doResize()
#
#     @header.addSubView headerInput = new Chat_HeaderConsole delegate : @
#     @content.addSubView consoleList = new Chat_IrcListView (itemClass : Chat_IrcListItemView, delegate: @, autoScroll: yes), (KDDataPath:"consoleMessages", KDDataSource:@getData())
#
#   doResize: ->
#     @content.setHeight @getHeight() - @header.getHeight()
#     yes
#
# class Chat_IrcUsersView extends Chat_ViewStructure
#   viewAppended:->
#     super
#     @header.addSubView headerSearch = new Chat_HeaderSearch delegate : @
#
# class Chat_FriendsAndRoomsView extends KDView
#   viewAppended:->
#     @setHeight "auto"
#     @addSubView friends = new Chat_FriendsView delegate : @getDelegate(), rightTabs: @getOptions().rightTabs
#     @addSubView rooms = new Chat_RoomsView (delegate : @getDelegate()), @getData() #irc-client
#
# class Chat_FriendsView extends Chat_ViewStructure
#
#   _windowDidResize:()=>
#     @doResize()
#
#   viewAppended:->
#     super
#     @header.addSubView headerSearch = new Chat_HeaderSearch delegate : @
#     @content.addSubView friendsList = new MembersListViewDeprecate (itemClass : Chat_FriendListItem, delegate: @),(KDDataPath:"Data.friends",KDDataSource: @account)
#     @content.addSubView roomsList   = new Chat_RoomsListView {delegate: @}, (KDDataPath:"Data.chatRooms", KDDataSource: @account.chatClient)
#
#     @footer.destroy()
#
#     @listenWindowResize()
#
#     @doResize()
#
#   doResize: ->
#     @content.setHeight @getDelegate().getHeight()/2 - @header.getHeight()
#     yes
#
# class Chat_FriendListItem extends MembersListItemDeprecate
#   constructor: (options, data) ->
#     options or= {}
#     options.draggingEnabled = yes
#     super options, data
#
#     chatMainTabs  = @getDelegate().getOptions().delegate.getOptions().rightTabs
#
#     @listenTo
#       KDEventTypes: 'ActivateChatPane'
#       listenedToInstance: chatMainTabs
#       callback: (mainTabs, event) =>
#         activePane = chatMainTabs.getActivePane()
#         if @getData().id + '_tab' is activePane.id
#           @stopBlink()
#
#     @listenTo
#       KDEventTypes: 'NewChatMessageReceived'
#       listenedToInstance: @getSingleton('site').account.chatClient
#       callback: (pubInst, event) =>
#         return if @getData().id isnt event.initiatorId
#
#         activePane = chatMainTabs.getActivePane()
#         if activePane
#           if activePane.id isnt event.initiatorId + '_tab'
#             @blink()
#         else
#           @blink()
#
#   click:->
#     super
#     {profile} = @getData()
#     @handleEvent type : "ChatFriendClick"
#
#   dragOptions:()->
#     revert:         "invalid"
#     revertDuration: 200
#     appendTo:       "body"
#     containment:    "body"
#     cursorAt :
#       left      : -10
#       top       : 5
#     helper:
#       ()=>
#         $ "<div class='user-item drag-helper clearfix'>
#             <span class='icon'>
#               <img src='' />
#             </span>
#             <span class='title-user-item'>#{@getData().profile.fullname}</span>
#           </div>"
#     opacity:        1
#     scroll:         yes
#
#   isDraggable: ->
#     yes
#
#   dragStart:(event,ui)=>
#     @getDomElement().data('obj',@getData())
#
#   partial:(data)->
#     profile = data
#     $ "<div class='irc-activity'>
#        <h3 class='clearfix'>
#          <a href='/#/profile/#{profile.nickname}' class='user-avatar propagateProfile' title='#{profile.fullname}'>
#            <img src='./images/#{profile.nickname}.avatar.png' alt=\"#{profile.fullname}'s profile picture\"/>
#          </a>
#          <a href='/#/profile/#{profile.nickname}' class='user-title propagateProfile' title='#{profile.fullname}'>#{profile.fullname}</a>
#        </h3>
#      </div>"
#
# class Chat_RoomsView extends Chat_ViewStructure
#
#   _windowDidResize:()=>
#     @doResize()
#
#   viewAppended:->
#     super
#     @header.addSubView headerSearch = new Chat_HeaderRoomSearch delegate : @
#     # items = [
#     #   { nickname  : "#kodingen", users : 2 }
#     #   { nickname  : "#javascript", users : 501 }
#     #   { nickname  : "#c++", users : 1301 }
#     #   { nickname  : "#ruby", users : 287 }
#     #   { nickname  : "#python", users : 412 }
#     #   { nickname  : "#node.js", users : 309 }
#     #   { nickname  : "#php", users : 28 }
#     # ]
#     #
#     # @content.addSubView friendsList = new Chat_RoomList (itemClass : Chat_RoomListItem),{items}
#     @content.addSubView roomList = new Chat_RoomList (itemClass : Chat_RoomListItem),(KDDataPath:"rooms", KDDataSource:@getData())
#     roomList.setScroller scrollView : @content, fractionBelowTrigger : .80
#
#     roomList.unsetClass "kdlistview-default"
#     roomList.setClass "kdlistview-irc"
#
#     @footer.destroy()
#
#     @listenWindowResize()
#
#     @doResize()
#
#   doResize: ->
#     @content.setHeight @getDelegate().getHeight()/2 - @header.getHeight()
#     yes
#
#   joinRoom:(roomName, callback)->
#     @getData().persist
#       action : "addTo"
#       dataPath : "joinedRooms"
#     ,roomName, ()->
#       callback?()
#
#   filterRooms:(filterString, callback)->
#     @getData().persist
#       action : "filter"
#       dataPath : "rooms"
#     , filterString:filterString, ()->
#       callback?()
#
# class Chat_RoomList extends KDDataSortableListViewController
#   constructor: ->
#     super
#     @addSorter (items) ->
#       items.sort (a, b) ->
#         _a = a.population or 0
#         _b = b.population or 0
#         _b - _a
#
#       items
#
# class Chat_RoomListItem extends KDDataListItemView
#   constructor: (options, data) ->
#     super
#     @setTooltip data.description, {defaultPosition: 'left', edgeOffset: -5}
#
#   click:(pubInst)->
#     # {profile} = @getData()
#     @handleEvent type : "ChatRoomClick"
#
#   partial:()->
#     data = @getData()
#     {population} = data
#     @getDelegate()?.sort()
#     str = "<div class='irc-activity'>
#        <h3 class='clearfix'>
#          <a href='/#/chatroom/#{name = data.roomName}' class='room-title' title='#{name} Room'>#{name}</a>
#         "
#     if population
#       str += "<a href='/#/chatroom/#{population}' class='online-users' title='#{population} users'>#{population} online</a>"
#
#     str += "</h3></div>"
#
#     $ str
#
#
# class Chat_GenericChatWindow extends Chat_ViewStructure
#   viewAppended:->
#     super
#     @header.$().hide()
#     @footer.addSubView @input = new Chat_HeaderInput delegate : @
#     @content.setHeight @getHeight() - @footer.getHeight()
#
#     @listenTo
#       KDEventTypes        : "KDTabPaneActive"
#       listenedToInstance  : @getDelegate()
#       callback            : @setFocus
#
#   setFocus:(pubInst)=>
#     # log @input.inputField,"set focus",pubInst
#     @input.inputField.setFocus()
#
#   cleanUp:()->
#     @input.inputField.setValue ""
#
#   notifyError:()->
#     new KDNotificationView
#       title   : "Ooops."
#       content : "Something weird happened,<br/>message couldn't be sent!!!"
#       duration: 1000
#   ###
#   keyUpOnInput:(pubInst,event)=>
#     (@getSingleton "windowController").setKeyView @
#   ###
#
# class Chat_InternalChatWindow extends Chat_GenericChatWindow
#   viewAppended:->
#     super
#
#     chatClient = @getSingleton('site').account.chatClient
#
#     if @getOptions().accounts
#       chatClient.initiateByAccounts @getOptions().accounts, (delegate: @getDelegate()), (p2pChat)=>
#         @dataSource = p2pChat
#         @buildInterface()
#       #@dataSource           = new ChatP2P (accounts: @getOptions().accounts, delegate: @getDelegate()), {}
#     else
#       chatClient.initiateByInstance @getOptions().room, (p2pChat) =>
#         @dataSource           = p2pChat
#         @buildInterface()
#
#
#   buildInterface: ->
#     controls              = new KDView
#     controls.setHeight 'auto'
#     #inConversationList    = new KDView
#
#     ###
#     createGroupChatButton = new KDButtonView
#       title: '+ Add people to this chat'
#       callback: =>
#         @handleEvent type: 'ShowAddPeopleToThisChat'
#
#     controls.addSubView createGroupChatButton
#     ###
#     controls.addSubView new Chat_InternalChatRecipients {}, (KDDataPath: 'accounts', KDDataSource: @dataSource)
#
#     @content.addSubView controls
#
#     # @listenTo
#     #   KDEventTypes        : "focus"
#     #   listenedToInstance  : @input.inputField
#     #   callback            : @keyUpOnInput
#
#     @listenTo
#       KDEventTypes: 'ChangeTitle'
#       listenedToInstance  : @dataSource
#       callback  : (pubInst, data) =>
#         tabPane = @getDelegate()
#         tabPane.setTitle data.title
#
#     @listenTo
#       KDEventTypes: 'AddedAccounts'
#       listenedToInstance: @dataSource
#       callback: (p2pChat, data) =>
#         log '---->', p2pChat.getDelegate(), p2pChat
#         tab = p2pChat.getDelegate() or p2pChat.getOptions().delegate
#         tab.changeId p2pChat.id + '_tab'
#
#     @listenTo
#       KDEventTypes: 'P2PChatClose'
#       listenedToInstance: @dataSource
#       callback: (p2pChat, data) =>
#         @getOptions().delegate.delegate.removePane @getOptions().delegate
#
#     @listenTo
#       KDEventTypes: 'ChatTabClose'
#       listenedToInstance: @getDelegate()
#       callback: (pubInst, event) =>
#         log 'we have to destroy chat ', pubInst, event, @dataSource
#         @getSingleton('site').account.chatClient.removeRoomFromOpenedList @dataSource
#
#     @input.inputField.setFocus()
#     @content.addSubView chatMessagesList = new Chat_InternalChatListView {}, (KDDataPath:"messages", KDDataSource: @dataSource)
#
#     @listenTo
#       KDEventTypes        : 'ClickedMessageInTheList'
#       listenedToInstance  : chatMessagesList
#       callback            : (pubInst, event) =>
#         @input.inputField.setValue @input.inputField.getValue() + '@' + event.message.origin.profile.fullname
#         @input.inputField.setFocus()
#
#
#
#   isDroppable: ->
#     yes
#
#   dropOver: (event, ui) ->
#     ui.helper.addClass 'drop-is-acceptable'
#
#   dropOut: (event, ui) ->
#     ui.helper.removeClass 'drop-is-acceptable'
#
#   dropAccept: (item) ->
#     if item.data('obj') instanceof Account
#       yes
#     else
#       no
#
#   keyDown:(event)=>
#     switch event.which
#       when 13 #enter
#         msg = @input.inputField.getValue()
#         @dataSource.sendMessage message:msg
#         do @cleanUp
#
#
#   jQueryDrop: (event, ui) ->
#     item = ui.draggable.data('obj')
#     log 'dropping item', item
#
#     @handleEvent type: 'ChatFriendsSelectorAddToThisChat', accounts: [item]
#
# class Chat_InternalChatRecipientsController extends KDDataListViewController
#   instantiateListItems: (items) ->
#     for item in items
#       @addListItem new Chat_InternalChatRecipientItemView {}, item
#
#   addItems: (source, items) ->
#     for item in items
#       @addListItem new Chat_InternalChatRecipientItemView {}, item
#
#   removeItem: (instance, a) ->
#     log 'remove item', instance, a
#
#
#
# class Chat_InternalChatRecipients extends Chat_InternalChatRecipientsController
#   constructor: ->
#     super
#     @setClass 'chat-recipients'
#
# class Chat_InternalChatRecipientItemView extends KDDataListItemView
#   partial: (account) ->
#     $ "<div>#{account.profile.fullname}</div>"
#
#
# class Chat_IrcChatWindow extends Chat_GenericChatWindow
#
#   _windowDidResize:()=>
#     @doResize()
#
#   viewAppended:->
#     @addSubView @header  = new Chat_IrcTabPaneHeader()
#     @addSubView @content = new SplitView
#       domId : "irc-split"
#       views : [panelLeft = new KDScrollView(cssClass : "bordered"),panelRight = new KDScrollView()]
#       sizes : ["62%","38%"]
#     @addSubView @footer  = new Chat_IrcTabPaneFooter()
#
#     @header.$().hide()
#     @footer.addSubView @connectButton = new KDButtonView
#       title : "Connect to IRC"
#       style : "clean-gray"
#       callback    : ()=>
#         @getData().getOptions().client.persist
#           action : "set"
#           dataPath : "connected"
#
#     @listenTo
#       KDEventTypes :
#         className : "Data"
#         property : "connected"
#       listenedToInstance : @getData().getOptions().client
#       callback : (client, data)=>
#         return unless client.connected
#         @connectButton.destroy()
#         @footer.addSubView @input = new Chat_HeaderInput delegate : @
#         @input.inputField.setFocus()
#
#     @doResize()
#
#     @listenTo
#       KDEventTypes        : "KDTabPaneActive"
#       listenedToInstance  : @getDelegate()
#       callback            : @setFocus
#
#     @listenWindowResize()
#
#     panelLeft.addSubView new Chat_IrcListView (itemClass : Chat_IrcListItemView, delegate: @, autoScroll: yes), (KDDataPath:"messages", KDDataSource:@getData())
#     panelRight.addSubView new Chat_MemberListView itemClass : Chat_MemberListItemView, (KDDataPath:"names", KDDataSource:@getData())
#
#     # @listenTo
#     #   KDEventTypes        : "focus"
#     #   listenedToInstance  : @input.inputField
#     #   callback            : @keyUpOnInput
#
#   setFocus:(pubInst)=>
#     # log @input.inputField,"set focus",pubInst
#     @input?.inputField.setFocus()
#
#   doResize: ->
#     @content.setHeight @getHeight() - @footer.getHeight()
#     yes
#
#   keyDown:(e, vent)->
#     switch event.which
#       when 13 #enter
#         message = @input.inputField.getValue()
#
#         do @cleanUp
#         @getData().persist
#           action: "addTo"
#           dataPath: "messages"
#         ,{message}
#
# class Chat_IrcSplitContent extends KDView
#   constructor:->
#     super
#     @setClass "irc-panel border-box"
#
# class Chat_IrcTabPaneHeader extends KDView
#   constructor:->
#     super
#     @setClass "irc-tab-pane-header"
#
# class Chat_IrcTabPaneFooter extends KDView
#   constructor:->
#     super
#     @setClass "irc-tab-pane-footer"
#
# class Chat_HeaderContent extends KDView
#   constructor:->
#     super
#     @setClass "header-content"
#
# class Chat_HeaderInput extends Chat_HeaderContent
#   viewAppended:()->
#     @addSubView @inputField = new Chat_KDInputView
#       name    : "msg-input"
#       hint    : "Type your message..."
#
#     @listenTo
#       KDEventTypes:
#         eventType: 'keyup'
#       listenedToInstance: @inputField
#       callback: (pubInst, event)=>
#         @getDelegate().keyDown event
#
#
# class Chat_HeaderConnections extends Chat_HeaderContent
#   viewAppended:()->
#     delegate = @getDelegate()
#     @addSubView addButton = new KDButtonView
#       style    : "small-gray fl"
#       title    : "Add..."
#       icon     : yes
#       iconClass: "plus"
#       callback : ()->
#         delegate.handleEvent
#           type    : "IRC_AddConnection"
#
# class Chat_HeaderConsole extends Chat_HeaderContent
#   viewAppended:()->
#     @addSubView @inputField = new Chat_KDInputView
#       name     : "console-input"
#       defaultValue : "/your command"
#
#     @inputField.listenTo
#       KDEventTypes:
#         eventType: "mouseup"
#       listenedToInstance: @inputField
#       callback: ()->
#         @selectAll()
#         yes
#
#     @listenTo
#       KDEventTypes:
#         eventType: "keyup"
#       listenedToInstance: @inputField
#       callback: (inputField,event)->
#         switch event.which
#           when 13
#             #@getDelegate().getData() - irc client
#             log 'delegate', @getDelegate().getData(), event, inputField
#             @getDelegate().getData().doRawCommand inputField.getValue()
#             inputField.setValue '/'
#
# class Chat_HeaderSearch extends Chat_HeaderContent
#   viewAppended:()->
#     @addSubView @inputField = new Chat_KDInputView
#       name     : "search"
#       defaultValue : "Search..."
#
#     @inputField.listenTo
#       KDEventTypes:
#         eventType: "mouseup"
#       listenedToInstance: @inputField
#       callback: ()->
#         @selectAll()
#
#     @addSubView searchIcon = new KDCustomHTMLView "span"
#     searchIcon.setClass "magnifying-glass for-input"
#
# class Chat_HeaderRoomSearch extends Chat_HeaderSearch
#   viewAppended:()->
#     super
#
#     @listenTo
#       KDEventTypes:
#         eventType: "keyup"
#       listenedToInstance: @inputField
#       callback: (inputField,event)->
#         switch event.which
#           when 13
#             @inputField.selectAll()
#             @delegate.joinRoom inputField.getValue(), ()->  #enter
#           else @delegate.filterRooms inputField.getValue(), ()->
#
# class Chat_KDInputView extends KDInputView
#   constructor:->
#     super
#     @setClass "full-input"
#
#   focus:(event)->
#     (@getSingleton "windowController").setKeyView @
#
#   click: ->
#     (@getSingleton "windowController").setKeyView @
#     no
#
# class Chat_TopButtons extends KDView
#   constructor:(options,data)->
#     super options,data
#
#   formSubmit:(formData)-> noop
#
#   viewAppended:()->
#     delegate = @getDelegate()
#     # ircTestButton = new KDButtonView
#     #   title:"test streaming"
#     #   callback: =>
#     #     KDData::invokeServerSide
#     #       test :
#     #         params : "#nodejs"
#     # @addSubView ircTestButton
#
#     connectButton = new KDButtonView
#       title : "Connect"
#       style : "clean-gray"
#       icon  : yes
#       iconClass : "plus"
#       callback :()->
#         KDData::invokeServerSide
#           doIrcConnect :
#             params        : null
#             middleware    : (err, params)=>
#               unless err?
#                 new KDNotificationView
#                   title   : "IRC Connected"
#                   content : "You have been connected to #Kodingen channel."
#                   duration: 1000
#                 @disable()
#
#         # delegate.handleEvent
#         #   type    : "IRC_AddConnection"
#
#     @addSubView connectButton
#
#     settingsButton = new KDButtonView
#       title : "Settings"
#       style : "clean-gray"
#       icon  : yes
#       iconClass : "cog"
#       callback : noop
#     @addSubView settingsButton