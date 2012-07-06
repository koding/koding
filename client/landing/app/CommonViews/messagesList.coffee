class MessagesListItemView extends KDListItemView
  constructor:(options, data)->
    super
  
  partial:(data)->
    "<div>#{data.subject or '(No title)'}</div>"

class MessagesListView extends KDListView

class MessagesListController extends KDListViewController
  
  constructor:(options, data)->
    options.subItemClass or= InboxMessagesListItem
    options.listView or= new MessagesListView
      # lastToFirst : yes

    super options, data

    @getListView().registerListener
      KDEventTypes  : "AvatarPopupShouldBeHidden"
      listener      : @
      callback      : => 
        @propagateEvent KDEventType : 'AvatarPopupShouldBeHidden'

  fetchMessages:(callback)->
    appManager.tell 'Inbox', 'fetchMessages',
      as          : 'recipient'
      limit       : 10
      sort        :
        timestamp : 1
    , (err, messages)=>
      # @propagateEvent KDEventType : "ClearMessagesListLoaderTimeout"
      @removeAllItems()
      @instantiateListItems messages

      unreadCount = 0
      for message in messages
        unreadCount++ unless message.flags_?.read
          
      @propagateEvent KDEventType : "MessageCountDidChange", {count : unreadCount}
      callback? err,messages

  fetchNotificationTeasers:(callback)->
    {currentDelegate} = @getSingleton('mainController').getVisitor()
    # console.log 'im kule', currentDelegate
    currentDelegate.fetchActivityTeasers? {
      targetName: $in: [
        'CReplieeBucketActivity'
        'CFolloweeBucketActivity'
        'CLikeeBucketActivity'
      ]
    }, {
      options:
        limit: 8
        sort:
          timestamp: -1
    }, (err, items)=>
      if err
        warn "There was a problem fetching notifications!",err
      else
        #@instantiateListItems items
        @propagateEvent KDEventType : 'NotificationCountDidChange', {count : items.length}
        callback? items


  instantiateListItems:(items = [])->
    listView = @getListView()
    items.forEach (itemModel) =>
      itemView = listView.itemClass delegate : listView,itemModel
      itemView.registerListener KDEventTypes : 'click', listener : @, callback : listView.itemClicked

      @itemsOrdered[if @getOptions().lastToFirst then 'unshift' else 'push'] itemView
      @itemsIndexed[itemView.getItemDataId()] = itemView
      listView.addItemView itemView

      itemView

class NotificationListItem extends KDListItemView

  activityNameMap = ->
    JStatusUpdate : "your status update."
    JCodeSnip     : "your status update."

  actionPhraseMap = ->
    comment : "commented on"
    reply   : "commented on"
    # reply   : "replied to"
    follow  : "followed"
    share   : "shared"
    commit  : "committed"
  
  constructor:(options,data)->
    options = $.extend
      tagName        : "li"
      linkGroupClass : LinkGroup
      avatarClass    : AvatarView
    ,options

    super options,data

    group = data.map (participant)->
      constructorName : participant.targetOriginName
      id              : participant.targetOriginId
    
    @participants = new options.linkGroupClass {group}
    @avatar       = new options.avatarClass {
      size    : {width: 40, height: 40}
      origin  : group[0]
    }

  pistachio:->
    """
      <div class='avatar-wrapper fl'>
        {{> @avatar}}
      </div>
      <div class='right-overflow'>
        <p>{{> @participants}} {{@getActionPhrase #(0.as)}} {{@getActivityPlot #(0.sourceName)}}</p>
        <footer>
          <time>{{$.timeago @getLatestTimeStamp #(0.timestamp)}}</time>
        </footer>
      </div>
    """
  
  getLatestTimeStamp:()->
    data = @getData()
    return data.slice(-1)[0].timestamp
  
  getActionPhrase:(as)->
    return actionPhraseMap()[as]

  getActivityPlot:(sourceName)->
    return activityNameMap()[sourceName]
    
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  click:->
    {sourceName,sourceId} = @getData()[0]
    contentDisplayController = @getSingleton('contentDisplayController')
    list = @getDelegate()
    list.propagateEvent KDEventType : 'AvatarPopupShouldBeHidden'
    bongo.cacheable sourceName, sourceId, (err, source)=>
      appManager.tell "Activity", "createContentDisplay", source
    


