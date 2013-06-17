class MessagesListItemView extends KDListItemView
  constructor:(options, data)->
    super

  partial:(data)->
    "<div>#{data.subject or '(No title)'}</div>"

class MessagesListView extends KDListView

class MessagesListController extends KDListViewController

  constructor:(options, data)->
    options.itemClass           or= InboxMessagesListItem
    options.listView            or= new MessagesListView
    options.startWithLazyLoader   = yes
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

class NotificationListItem extends KDListItemView

  activityNameMap = ->
    JStatusUpdate   : "your status update."
    JCodeSnip       : "your status update."
    JAccount        : "started following you."
    JPrivateMessage : "your private message."
    JComment        : "your comment."
    JDiscussion     : "your discussion."
    JOpinion        : "your opinion."
    JReview         : "your review."

  bucketNameMap = ->
    CReplieeBucketActivity  : "comment"
    CFolloweeBucketActivity : "follow"
    CLikeeBucketActivity    : "like"

  actionPhraseMap = ->
    comment : "commented on"
    reply   : "replied to"
    like    : "liked"
    follow  : ""
    share   : "shared"
    commit  : "committed"

  constructor:(options = {}, data)->

    options.tagName        or= "li"
    options.linkGroupClass or= LinkGroup
    options.avatarClass    or= AvatarView

    super options, data

    @setClass bucketNameMap()[data.bongo_.constructorName]

    @snapshot = JSON.parse Encoder.htmlDecode data.snapshot

    # group = data.map (participant)->
    #   constructorName : participant.targetOriginName
    #   id              : participant.targetOriginId

    {group} = @snapshot

    # Cleanup my activities on my content
    myid = KD.whoami()?.getId()

    return  unless myid

    group = (member for member in group when member.id isnt myid)

    @participants = new options.linkGroupClass {group}
    @avatar       = new options.avatarClass
      size     :
        width  : 40
        height : 40
      origin   : group[0]

    @timeAgoView = new KDTimeAgoView {}, @getLatestTimeStamp @getData().dummy

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
      <div class='avatar-wrapper fl'>
        {{> @avatar}}
      </div>
      <div class='right-overflow'>
        <p>{{> @participants}} {{@getActionPhrase #(dummy)}} {{@getActivityPlot #(dummy)}}</p>
        <footer>
          {{> @timeAgoView}}
        </footer>
      </div>
    """

  getLatestTimeStamp:->
    data = @getData()
    # lastUpdateAt = @snapshot.group[@snapshot.group.length-1]
    lastUpdateAt = @snapshot.group.modifiedAt
    return lastUpdateAt or data.createdAt

  getActionPhrase:->
    data = @getData()
    if @snapshot.anchor.constructorName is "JPrivateMessage"
      @unsetClass "comment"
      @setClass "reply"
      actionPhraseMap().reply
    else
      actionPhraseMap()[bucketNameMap()[data.bongo_.constructorName]]

  getActivityPlot:->
    data = @getData()
    return activityNameMap()[@snapshot.anchor.constructorName]

  click:->

    showPost = (err, post)->
      if post
        internalApp = if post.constructor.name is "JApp" then "Apps" else "Activity"
        KD.getSingleton('router').handleRoute "/#{internalApp}/#{post.slug}", state:post

      else
        new KDNotificationView
          title : "This post has been deleted!"
          duration : 1000

    if @snapshot.anchor.constructorName is "JPrivateMessage"
      appManager = KD.getSingleton "appManager"
      appManager.open "Inbox"
      appManager.tell 'Inbox', "goToMessages"
    else if @snapshot.anchor.constructorName in ["JComment", "JReview", "JOpinion"]
      KD.remote.api[@snapshot.anchor.constructorName].fetchRelated @snapshot.anchor.id, showPost
    else unless @snapshot.anchor.constructorName is "JAccount"
      KD.remote.api[@snapshot.anchor.constructorName].one _id : @snapshot.anchor.id, showPost
