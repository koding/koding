class MessagesListItemView extends KDListItemView
  constructor:(options, data)->
    super

  partial:(data)->
    "<div>#{data.subject or '(No title)'}</div>"

class MessagesListView extends KDListView

class MessagesListController extends KDListViewController

  constructor:(options, data)->
    options.itemClass           or= MessagesListItemView
    options.listView            or= new MessagesListView
    options.startWithLazyLoader   = yes
    options.lazyLoaderOptions     =
      partial                     : ''
      spinnerOptions              :
        loaderOptions             :
          color                   : '#6BB197'
        size                      :
          width                   : 32

    super options, data

    @getListView().on "AvatarPopupShouldBeHidden", =>
      @emit 'AvatarPopupShouldBeHidden'

  fetchMessages:(callback)->
    return callback? yes  unless KD.isLoggedIn()
    KD.getSingleton("appManager").tell 'Inbox', 'fetchMessages',
      # as          : 'recipient'
      limit       : 3
      sort        :
        timestamp : -1
    , (err, messages)=>
      @removeAllItems()
      @instantiateListItems messages

      unreadCount = 0
      for message in messages
        unreadCount++ unless message.flags_?.read

      @emit "MessageCountDidChange", unreadCount
      @hideLazyLoader()
      callback? err,messages

  fetchNotificationTeasers:(callback)->
    KD.whoami().fetchActivityTeasers? {
      targetName: $in: [
        # 'CActivity'
        'CReplieeBucketActivity'
        'CFolloweeBucketActivity'
        'CLikeeBucketActivity'
        'CGroupJoineeBucketActivity'
        'CNewMemberBucketActivity'
        'CGroupLeaveeBucketActivity'
      ]
    }, {
      limit: 8
      sort:
        timestamp: -1
    }, (err, items)=>
      if err
        warn "There was a problem fetching notifications!",err
      else
        unglanced = items.filter (item)-> item.getFlagValue('glanced') isnt yes
        @emit 'NotificationCountDidChange', unglanced.length
        callback? items
      @hideLazyLoader()


