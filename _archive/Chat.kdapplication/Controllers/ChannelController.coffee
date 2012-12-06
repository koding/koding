class ChannelController extends KDEventEmitter #KDViewController
  constructor: (options = {}, data) ->
    @messages = []
    @unreadCount = 0
    @participants = {}
    @name = options.name
    @view = options.view

    # Remove unread count when the tab is active
    @view.listenTo
      KDEventTypes: [ eventType: "KDTabPaneActive" ]
      listenedToInstance: @view
      callback: => 
        @unreadCount = 0
        @view.setUnreadCount @unreadCount

  addOnlineUser: (name) ->
    KD.remote.api.JAccount.one "profile.nickname" : name, (err, account)=>
      viewInstance = @view.addRosterItem account
      @participants[name] = viewInstance
      viewInstance

  removeOfflineUser: (name) ->
    viewInstance = @participants[name]
    @view.removeRosterItem viewInstance

  messageReceived: (message) ->
    @messages.push message
    unless @view.isActive()
      @unreadCount++ 
      @view.setUnreadCount @unreadCount
    @view.newMessage message