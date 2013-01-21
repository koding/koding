class ChannelView extends KDTabPaneView
  constructor: (options = {}, data) ->
    super options, data

    @chatController = new KDListViewController
      itemClass: ChatListItemView
    @rosterController = new RosterController

    @chatController.getView().setHeight options.listHeight || 500
    @rosterController.getView().setHeight options.listHeight || 500

    @listenTo
      KDEventTypes: "ContextMenuItemClicked"
      listenedToInstance: @rosterController
      callback: (pubInst, {itemView, contextMenuItem}) =>
        @contextMenuItemSelected itemView, contextMenuItem

  viewAppended: ->
    @addSubView splitView = new KDSplitView
      sizes: ["60%","40%"]
      views: [
        @chatController.getView()
        @rosterController.getView()
      ]
    splitView.setHeight 500
    @addSubView @inputForm = new ChatInputFormView delegate : @

  addRosterItem: (item) ->
    @rosterController.addItem item

  removeRosterItem: (itemInstance) ->
    @rosterController.removeItem itemInstance

  newMessage: (message) ->
    @chatController.getListView().addItem message

  isActive: ->
    @getDomElement().hasClass "active"

  setUnreadCount: (count) ->
    title = "#{@name}"
    title += " (<span class='unread'>#{count}</span>)" if count

    @tabHandle.getDomElement().find("b").html title

  contextMenuItemSelected: (userView, contextMenuItem) ->
    {action} = contextMenuItem.getData()
    if action
      if @["contextMenuOperation#{action.capitalize()}"]?
        @rosterController.destroyContextMenu()
      @["contextMenuOperation#{action.capitalize()}"]? userView, contextMenuItem

  contextMenuOperationMentionUser: (userView, contextMenuItem) ->
    userData = userView.getData()
    @inputForm.appendChat "@#{userData.profile.nickname}"

  contextMenuOperationMentionUsers: (userView, contextMenuItem) ->
  contextMenuOperationInvitePrivateChat: (userView, contextMenuItem) ->
  contextMenuOperationInviteGroupChat: (userView, contextMenuItem) ->

class RosterController extends KDListViewController
  constructor: (options = {}, data) ->
    options.itemClass ?= ChannelListItemView
    super options, data

  addItem: (item) ->
    instance = @getListView().addItem item
    instance.registerListener
      KDEventTypes: 'contextmenu'
      listener    : @
      callback    : (pubInst, event) =>
        event.stopPropagation()
        event.preventDefault()
        @getContextMenu([pubInst], event)
        return no
    instance

  removeItem: (itemInstance) ->
    @getListView().removeItem itemInstance

  destroyContextMenu:->
    @contextMenu.destroy()

  getContextMenu: (itemViews, event) ->
    event.stopPropagation()
    event.preventDefault()

    @contextMenu.destroy() if @contextMenu
    items = @getContextMenuItems itemViews
    [itemView] = itemViews
    if items
      @contextMenu = new JContextMenu
        event    : event
        delegate : itemView
      , items

      @contextMenu.on "ContextMenuItemReceivedClick",(contextMenuItem)=>
        @handleContextMenuClick itemView, contextMenuItem
      return @contextMenu
    else
      return no

  handleContextMenuClick:(itemView, contextMenuItem)->
    event = KDEventType : 'ContextMenuItemClicked'
    @propagateEvent event, {itemView, contextMenuItem}

  getContextMenuItems: (itemViews) ->
    if itemViews.length > 1
      @getMultipleUsersMenu itemViews
    else
      [itemView] = itemViews
      # switch fileView.getData().type
      #   when "file"    then @getFileMenu fileView
      #   when "folder"  then @getFolderMenu fileView
      #   when "mount"   then @getMountMenu fileView
      @getUserMenu itemView

  getUserMenu: (userView) ->
    userData = userView.getData()

    items =
      "Mention"   :
        action: 'mentionUser'
      "Invite to private chat":
        action: 'invitePrivateChat'

  getMultipleUsersMenu: (userViews) ->
    items =
      'Mention':
        action: 'mentionUsers'
      'Invite to group chat':
        action: 'inviteGroupChat'

