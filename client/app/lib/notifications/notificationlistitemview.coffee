Promise                 = require 'bluebird'
kd                      = require 'kd'
KDCustomHTMLView        = kd.CustomHTMLView
KDListItemView          = kd.ListItemView
KDNotificationView      = kd.NotificationView
KDTimeAgoView           = kd.TimeAgoView
groupifyLink            = require '../util/groupifyLink'
getFullnameFromAccount  = require '../util/getFullnameFromAccount'
remote                  = require('../remote')
whoami                  = require '../util/whoami'
isKoding                = require '../util/isKoding'
isPublicChannel         = require '../util/isPublicChannel'
AvatarView              = require '../commonviews/avatarviews/avatarview'
JView                   = require '../jview'
LinkGroup               = require '../commonviews/linkviews/linkgroup'


module.exports = class NotificationListItemView extends KDListItemView

  JView.mixin @prototype

  activityNameMap =
    comment : 'status.'
    like    : 'status.'
    follow  : 'started following you.'
    join    : 'your group'
    leave   : 'your group'
    mention : 'status.'


  actionPhraseMap =
    comment  : 'commented on'
    reply    : 'replied to'
    like     : 'liked'
    follow   : ''
    share    : 'shared'
    commit   : 'committed'
    member   : 'joined'
    join     : 'joined'
    leave    : 'left'
    mention  : 'mentioned you in'


  constructor: (options = {}, data) ->

    options.tagName        or= 'a'
    options.linkGroupClass or= LinkGroup
    options.avatarClass    or= AvatarView
    options.cssClass         = kd.utils.curry 'clearfix', options.cssClass

    super options, data

    @updateHref()

    @participants = new KDCustomHTMLView
    @avatar       = new KDCustomHTMLView
    @activityPlot = new KDCustomHTMLView { tagName: 'span' }
    @timeAgoView  = new KDTimeAgoView null, @getLatestTimeStamp @getData().dummy

    @initializeReadState()


  viewAppended: ->
    promises = []
    promises.push @fetchActors()
    promises.push @getActivityPlot()

    Promise.all(promises).then =>
      @setTemplate @pistachio()
      @template.update()
    .catch (err) ->
      kd.warn err.description


  updateHref: ->

    { socialapi } = kd.singletons


    switch @getData().type
      when 'comment', 'like', 'mention'
        socialapi.message.byId { id: @getData().targetId }, (err, post) =>
          return kd.warn err  if err
          if not isKoding()
          then @setAttribute 'href', calculateReactivityLink post
          else @setAttribute 'href', groupifyLink "/Activity/Post/#{post.slug}"
      when 'follow'
        @setAttribute 'href', groupifyLink "/#{@actors.first.profile.nickname}"
      when 'join', 'leave'
        @setAttribute 'href', '#'


  click: (event) ->

    kd.utils.stopDOMEvent event

    showPost = (err, post) ->
      return kd.warn err if err
      if post
        # TODO group slug must be prepended after groups are implemented
        # groupSlug = if post.group is "koding" then "" else "/#{post.group}"
        if not isKoding()
        then kd.singletons.router.handleRoute calculateReactivityLink post
        else kd.singletons.router.handleRoute "/Activity/Post/#{post.slug}", { state: post }
      else
        new KDNotificationView
          title : 'This post has been deleted!'
          duration : 1000

    popupList = @getDelegate()
    popupList.emit 'AvatarPopupShouldBeHidden'

    switch @getData().type
      when 'comment', 'like', 'mention'
        { message } = kd.singletons.socialapi
        message.byId { id: @getData().targetId }, showPost
      when 'follow'        then kd.singletons.router.handleRoute "/#{@actors[0].profile.nickname}"
      when 'join', 'leave' then return


  initializeReadState: ->

    if @getData().glanced
    then @unsetClass 'unread'
    else @setClass 'unread'


  fetchActors: ->

    @actors          = []
    options          = @getOptions()
    { latestActors } = @getData()
    constructorName  = 'JAccount'
    origins          = latestActors.map (id) -> { id, constructorName }

    new Promise (resolve, reject) =>
      remote.cacheable origins, (err, actors) =>
        return reject err if err?
        @actors = actors
        @participants = new options.linkGroupClass { group: actors }
        @avatar       = new options.avatarClass
          size     :
            width  : 30
            height : 30
          origin   : @actors[0]
        resolve()


  getLatestTimeStamp: -> @getData().updatedAt


  getActionPhrase: -> actionPhraseMap[@getData().type]


  getActivityName: -> activityNameMap[@getData().type]


  getActivityPlot: ->

    new Promise (resolve, reject) =>
      data = @getData()
      adjective = ''
      if data.type in ['comment', 'like', 'mention']
        { message } = kd.singletons.socialapi
        message.byId { id: data.targetId }, (err, message) =>

          return reject err  if err or not message

          remote.cacheable 'JAccount', message.account._id, (err, origin) =>
            return reject err  if err or not origin

            isMine     = message.account._id is whoami().getId()
            isTheirOwn = @actors.length is 1 and @actors[0].getId() is origin.getId()

            adjective = if isMine then 'your'
            else if isTheirOwn then 'their own'
            else "#{getFullnameFromAccount origin}'s"

            @activityPlot.updatePartial "#{adjective} #{@getActivityName()}"
            resolve()
      else
        @activityPlot.updatePartial "#{@getActivityName()}"
        resolve()



  pistachio: ->
    """
    <div class='avatar-wrapper fl'>{{> @avatar}}</div>
    <div class='right-overflow'>
      {{> @participants}}
      {{  @getActionPhrase #(dummy)}}
      {{> @activityPlot}}
      {{> @timeAgoView}}
    </div>
    """




calculateReactivityLink = (post) ->

  channel = kd.singletons.socialapi.retrieveCachedItemById post.initialChannelId

  return  unless channel

  if isPublicChannel channel
  then "/Channels/#{channel.name.toLowerCase()}/#{post.id}"
  else "/Messages/#{channel.id}/#{post.id}"
