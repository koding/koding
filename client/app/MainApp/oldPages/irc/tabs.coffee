# class Chat_IrcTabs extends KDTabView
#   constructor:(options,data)->
#     options = options ? {}
#     super options,data
#     @$().css "overflow","hidden"
#   
#   createPanes:()->
#     tabNames = @getOptions().tabNames
#     if tabNames?
#       for name in tabNames
#         @addIrcTab name
# 
#   _resizeListen: (tab) ->
#     @listenWindowResize()
#   
#   addIrcTab:(title, id)->
#     tab = new @tabConstructor {cssClass:"irc-tab", delegate: @},null
#     tab.changeId id
#     @addPane tab
#     tab.setTitle title
#     @_resizeListen tab
#   
#   showPane: (paneInstance) ->
#     super
# 
#     @handleEvent type: 'ActivateChatPane', pane: paneInstance
#   
#   getPane: (id, name) ->
#     pane = @getPaneById id + '_tab'
#     unless pane
#       @addIrcTab name, id + '_tab'
#     else
#       @showPane pane
#       pane
#   
#   setPane:(options)->
#     pane = @getPaneByName(options.name)
#     if pane is false
#       @addIrcTab options.name
#     else
#       @showPane pane
#       pane
#       
# class Chat_MainTabs extends Chat_IrcTabs
#   appendHandleContainer: ->
#     super
#     @addSubView peopleSelector = new Chat_FriendsSelector delegate: @  
#   
#   viewAwaitingRefresh:(source,{action, args},{listenedPath,propagatedPath})=>
#     #FIXME: Doesn't work
#     # unless @loadingIndicator
#     #   position = "top"
#     #   @addSubView (@loadingIndicator = new KDView {cssClass : "loading-indicator #{position}", delegate : @,position},null),null,yes
#     # @setClass "showing-loading-indicator-on-#{position}"
#     # @loadingIndicator.show()
#   
#   refreshView:(source,{data, action, args},{listenedPath,propagatedPath})=>
#     # FIXME: awaiting doesn't work
#     # return super unless @loadingIndicator?
#     # position = @loadingIndicator.getOptions().position
#     # @unsetClass "showing-loading-indicator-on-#{position}"
#     # @loadingIndicator.hide()
# 
# class Chat_IrcTabPane extends KDTabPaneView
#   _windowDidResize:()=>
#     @doResize()
# 
#   viewAppended:()->
#     @doResize()
#     
#   doResize: ->
#     @setHeight @delegate.getHeight() - 29
#     
#   destroy: ->
#     @handleEvent type: 'ChatTabClose'
#     super
    # log 'destroying the tab'
#     
# 
# class Chat_IrcChatTabPane extends Chat_IrcTabPane
# 
# 
# class Chat_FriendsSelector extends KDView
#   constructor: (options, data) ->
#     options or= {}
#     options.cssClass = 'chat-friend-selector'
#     super options, data
#     
#     @$().css 'top', -229
# 
#     @listenTo
#       KDEventTypes: 'ShowAddPeopleToThisChat'
#       callback: =>
#         @show()
#           
#     @listenTo
#       KDEventTypes: 'HideAddPeopleToThisChat'
#       callback: =>
#         @hide()
#     
#   hide: ->
#     @$().animate
#       top: -229
#       
#   show: ->
#     @$().animate
#       top: @getDelegate().getTabHandleContainer().getHeight()
#       
#   viewAppended: ->
#     @setHeight '200px'
#     
#     @addSubView friendsList = new Chat_FriendsSelectorList {}, (KDDataPath:"Data.friends",KDDataSource: @getSingleton("site").account)
#     
#     
#     getAccounts = ->
#       accounts = []
#       for item in friendsList.items
#         if item.selected
#           accounts.push item.getData()
#           
#       accounts
#     
#     controls    = new KDView
#     controls.addSubView addButton = new KDButtonView
#       title: 'Add selected people to this chat'
#       callback: =>
#         @handleEvent type: 'ChatFriendsSelectorAddToThisChat', accounts: getAccounts()
#         @handleEvent type: 'HideAddPeopleToThisChat'
#         
#     controls.addSubView createButton = new KDButtonView
#       title: 'Create new chat with these people'
#       callback: =>
#         @handleEvent type: 'ChatFriendsSelectorCreateNewChat', accounts: getAccounts()
#         @handleEvent type: 'HideAddPeopleToThisChat'
#         
#     controls.addSubView cancelButton = new KDButtonView
#       title: 'Cancel'
#       callback: =>
#         @handleEvent type: 'HideAddPeopleToThisChat'
#         
#     @addSubView controls
#     
#     
# class Chat_FriendsSelectorListController extends KDDataListViewController
#   constructor:(options,data)->
#     super options,data
# 
#   instantiateListItems:(items)->
#     for item in items
#       instance = new Chat_FriendsSelectorItemView {}, item
#       @addListItem instance
# 
#   addItems:(source,item,{listenedPath,propagatedPath},index)=>
#     log 'adding items'
#     
# class Chat_FriendsSelectorList extends Chat_FriendsSelectorListController
#   
# class Chat_FriendsSelectorItemView extends KDListItemView
#   constructor: ->
#     super
#     @selected = no
#   
#   click: ->
#     if @selected
#       @deselect()
#     else
#       @select()
#       
#   select: ->
#     @selected = yes
#     @setClass 'selected'
#     
#   deselect: ->
#     @selected = no
#     @unsetClass 'selected'
#   
#   partial:(data)->
#     $ "<div class='irc-member clearfix'>
#         <div class='name'>#{data.profile.fullname}</div>
#       </div>"