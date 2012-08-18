class Chat12345 extends AppController
  constructor:(options = {}, data)->
    options.view = new ChatView
      cssClass : "content-page chat"

    super options, data

  bringToFront:()->
    super name : 'Chat'#, type : 'background'

  loadView:(mainView)->
    @addChannelTab 'public'
    @addOnlineUser name: "sntran", status: "online"

  addChannelTab: (name) ->
    view = @getOptions().view
    view.addChannelTab name

  addOnlineUser: (user) ->
    view = @getOptions().view
    userItemViewInstance = view.addOnlineUser user
    userItemViewInstance.registerListener
      KDEventTypes: 'click'
      listener    : @
      callback    : =>
        @addChannelTab user.name
    

class ChatView extends KDView
  viewAppended: ->
    @chatTabView = new KDTabView
    @rosterTabView = new KDTabView
    
    @addSubView splitView = new KDSplitView
      sizes: ["30%","70%"]
      views: [@rosterTabView, @chatTabView]

    @rosterTabView.addPane new TabPaneViewWithList 
      name: "topics"
      unclosable: true
      subItemClass: ChannelListItemView
      items: [
        {name: "erlang", status: "99 online"}
        {name: "nodejs", status: "10 online"}
        {name: "python", status: "25 online"}
      ]

    @rosterTabView.addPane new TabPaneViewWithList 
      name: "people"
      unclosable: true
      subItemClass: ChannelListItemView

  addChannelTab: (name) ->
    if @chatTabView.getPaneByName name
      @chatTabView.showPaneByName name
      return

    tabPane = @chatTabView.addPane new TabPaneViewWithList
      name: name
      subItemClass: ChatListItemView
      listHeight: 500

    formView = new KDFormView
    formView.addSubView input = new KDInputView
      name: "chatInput"
      cssClass: "fl"

    formView.addSubView new KDButtonView
      title: "send"
      cssClass: "fl"
      style: "cupid-green"
      callback: ->
        chatMsg = input.getValue()
        tabPane.addItem title: chatMsg
        input.setValue ""

    tabPane.addSubView formView

  addOnlineUser: (userItem) ->
    userPane = @rosterTabView.getPaneByName 'people'
    userPane.addItem userItem

###
This is a view for a tab pane that has a list view in there.
###
class TabPaneViewWithList extends KDTabPaneView
  constructor: (options = {}, data) ->
    super options, data
    controllerOptions = options.controllerOptions or {}
    
    if options.subItemClass
      controllerOptions.subItemClass = options.subItemClass

    @listController = new KDListViewController controllerOptions
    @listView = @listController.getListView()
    @listView.on 'ListItemClicked', =>
      log @getDelegate()
    @controllerView = @listController.getView()

    if options.listHeight
      @controllerView.setHeight 500

    if options.items
      @listController.instantiateListItems options.items

  viewAppended: ->
    @addSubView @controllerView
    if @getOptions().unclosable
      @hideTabCloseIcon()

  addItem: (item, index, animation) ->
    @listView.addItem item, index, animation


class ChatListItemView extends KDListItemView
  viewAppended: ->
    # @setPartial @getData().title
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    "<p>{{#(title)}}</p>"

class ChannelListItemView extends KDListItemView
  viewAppended: ->
    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    "<p>{{#(name)}} - {{#(status)}} </p>"
