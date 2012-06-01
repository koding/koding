# class Chat_MemberListViewController extends KDDataListViewController
# 
# class Chat_MemberListView extends Chat_MemberListViewController
#   constructor:(options,data)->
#     options = options ? {} 
#     options.cssClass = "kdlistview kdlistview-irc"
#     super options,data
#     
#   addItems: ->
#     super
#   
#   viewNeedsRefresh:(source, {data, action}, {listenedPath, propagatedPath})=>
#     return unless listenedPath is propagatedPath
#     @loadingIndicator?.hide()
# 
# class Chat_MemberListItemView extends KDListItemView
#   click:->
#     log @getData()
#   partial:()->
#     data = @getData()
#     $ "<div class='irc-member clearfix'>
#         <div class='name'>#{data}</div>
#       </div>"
# 
# #P2P groups
# class Chat_RoomsListViewController extends KDDataListViewController
#   constructor:(options,data)->
#     super options,data
#     
#   instantiateListItems:(items)->
#     for item in items
#       instance = new Chat_RoomsListItemView {delegate: @getDelegate(), list: @}, item
#       @addListItem instance
#     
#   addItems:(source,items, {listenedPath,propagatedPath},index)=>
#     for item in items
#       @_addItem item
#     
#   _addItem: (item)->
#     addItem = yes
#     for _item in @items
#       if _item.getData().id is item.id
#         _item.getData().setData item
#         _item.refreshPartial()
#         addItem = no
# 
#     if addItem
#       instance = new Chat_RoomsListItemView {delegate: @getDelegate(), list: @}, item
#       @addListItem instance
#       
#   addListItem: (instance) ->
#     super
#     instance.listenTo
#       KDEventTypes: 'RemovedAccounts'
#       listenedToInstance: instance.getData()
#       callback: =>
#         instance.refreshPartial()
#     
#   removeListItem: (instance) ->
#     super instance
#     @getSingleton('site').account.chatClient.removeRoom instance.getData()
#     #instance.getData().remove()
#     
# class Chat_RoomsListView extends Chat_RoomsListViewController
#   constructor:(options,data)->
#     options = options ? {} 
#     options.cssClass = "kdlistview kdlistview-irc"
#     super options,data
#     
# class Chat_RoomsListItemView extends KDListItemView
#   constructor: (options, data) ->
#     super options, data
# 
#     chatMainTabs  = @getDelegate().options.rightTabs
#     
#     @listenTo 
#       KDEventTypes: 'ActivateChatPane'
#       listenedToInstance: chatMainTabs
#       callback: (mainTabs, event) =>
#         activePane = chatMainTabs.getActivePane()
#         if @getData().id + '_tab' is activePane.id
#           @stopBlink()
#     @listenTo
#       KDEventTypes: 'NewChatMessageReceived'
#       listenedToInstance: @getSingleton('site').account.chatClient
#       callback: (pubInst, event) =>
#         return if data.id isnt event.initiatorId
#         
#         activePane = chatMainTabs.getActivePane()
#         if activePane
#           if activePane.id isnt event.initiatorId + '_tab'
#             @blink()
#         else
#           @blink()
#     @listenTo
#       KDEventTypes: 
#         eventType: 'ChangeTitle'
#       listenedToInstance: data
#       callback: =>
#         @refreshPartial() 
# 
#   _doButton: ->
#     btn = new RemoveChatGroupButton
#       title: 'Remove'
#       callback: =>
#         @getOptions().list.removeListItem @
#         
#     @addSubView btn, '.irc-member'
#     
#   viewAppended: ->
#     partial = @partial()
#     @setPartial partial
#     @_doButton()
#   
#   refreshPartial: (data) ->
#     partial = @partial()
#     @$().html partial
#     @_doButton data
#   
#   partial:()->
#     data = @getData()
#     inConversation = data.recipients.length
#     $ "<div class='irc-member clearfix'>
#         <div class='name'>#{data.title} <span>#{inConversation} person#{if inConversation > 2 then 's' else ''}</span></div>
#       </div>"
#     
#   click:->
#     super
#     @handleEvent type : "ChatRoomClick"
#     
# class RemoveChatGroupButton extends KDButtonView
#   click: ->
#     no
#     
#     
# class Chat_IrcListViewController extends KDDataListViewController
#   constructor:(options,data)->
#     super options,data
#     
#   instantiateListItems:(items)->
#     super
#     
#   addItems:(source,items,{listenedPath,propagatedPath},index)=>
#     super
# 
# class Chat_IrcListView extends Chat_IrcListViewController
#   constructor:(options,data)->
#     options = options ? {} 
#     options.cssClass = "kdlistview kdlistview-irc"
#     super options,data
# 
# class Chat_IrcListItemView extends KDListItemView
#   click:->
#     log @getData()
#   partial:()->
#     data = @getData()
#     $ "<div class='irc-activity clearfix'>
#         <div class='timestamp'>#{new Date(data.timestamp).format("UTC:HH:MM")}</div>
#         <div class='author'>#{data.nickname}:--></div>
#         <div class='content'>#{data.body}</div>
#       </div>"
# 
# class Chat_InternalChatListViewController extends KDDataListViewController
#   constructor:(options,data)->
#     super options,data
#     
#   instantiateListItems:(items)->
#     items = [items] unless $.isArray items
#     for message in items
#       itemInstance = new Chat_InternalChatListItemView null,message
#       #@items.push itemInstance
#       @addListItem itemInstance
#     @scrollDown()
#     
#   addItems: (chatModel, messages) ->
#     messages = [messages] unless $.isArray messages
#     for message in messages
#       itemInstance = new Chat_InternalChatListItemView null, message
#       @addListItem itemInstance
#       @scrollDown()
# 
#   addListItem: (instance) ->
#     super
#     @listenTo
#       KDEventTypes: 'ClickedMessageInTheList'
#       listenedToInstance: instance
#       callback: (pubInst, event) =>
#         @handleEvent type: 'ClickedMessageInTheList', message: pubInst.getData()
# 
# class Chat_InternalChatListView extends Chat_InternalChatListViewController
#   constructor:(options,data)->
#     options = options ? {} 
#     options.cssClass = "kdlistview kdlistview-internal-chat"
#     super options,data
#     
#   scrollDown: ->
#     x = @$().closest(".kdscrollview > .kdview").height()
#     @$().closest(".kdscrollview").animate (scrollTop : x),200
# 
# class Chat_InternalChatListItemView extends KDListItemView
#   click:->
#     log @getData(), @
#     @handleEvent type: 'ClickedMessageInTheList'
#     
#   partial:(data)->
#     return unless data
#     if data.type is 'system'
#       @systemMessage data
#     else
#       @userMessage data
#      
#      
#   systemMessage: (data) ->
#      $("<div class='irc-activity irc-system-activity'>
#         <h3>***</h3>
#         <p>#{data.message}</p>
#       </div>")
#       
#   userMessage: (data) ->
#     profile = data.origin?.profile
#     createdAt = data.createdAt or new Date().getTime()
#     $("<div class='irc-activity'>
#        <h3>
#          <a href='/#/profile/#{profile?.nickname}' class='user-avatar propagateProfile' title='#{profile?.fullname}'>
#            <img src='./images/#{profile?.nickname}.avatar.png' alt=\"#{profile?.fullname}'s profile picture\"/>
#          </a>
#          <a href='/#/profile/#{profile?.nickname}' class='user-title propagateProfile' title='#{profile?.fullname}'>#{profile?.fullname}</a>
#          <abbr class='timeago' title='#{new Date(createdAt).format 'isoUtcDateTime'}'></abbr>
#        </h3>
#        <p>#{data.message}</p>
#      </div>").find("abbr.timeago").timeago().end()
