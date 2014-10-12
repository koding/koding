class NotificationListItemView extends KDListItemView

  JView.mixin @prototype

  activityNameMap =
    comment : "status."
    like    : "status."
    follow  : "started following you."
    join    : "your group"
    leave   : "your group"
    mention : "status."

  actionPhraseMap =
    comment  : "commented on"
    reply    : "replied to"
    like     : "liked"
    follow   : ""
    share    : "shared"
    commit   : "committed"
    member   : "joined"
    join     : "joined"
    leave    : "left"
    mention  : "mentioned you in"

  constructor: (options = {}, data) ->

    options.tagName        or= "a"
    options.linkGroupClass or= LinkGroup
    options.avatarClass    or= AvatarView
    options.cssClass         = KD.utils.curry 'clearfix', options.cssClass

    super options, data


    @participants = new KDCustomHTMLView
    @avatar       = new KDCustomHTMLView
    @activityPlot = new KDCustomHTMLView tagName: "span"
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
      warn err.description


  click: (event) ->

    KD.utils.stopDOMEvent event

    showPost = (err, post)->
      return warn err if err
      if post
        # TODO group slug must be prepended after groups are implemented
        # groupSlug = if post.group is "koding" then "" else "/#{post.group}"
        KD.singletons.router.handleRoute "/Activity/Post/#{post.slug}", { state: post }
      else
        new KDNotificationView
          title : "This post has been deleted!"
          duration : 1000

    popupList = @getDelegate()
    popupList.emit 'AvatarPopupShouldBeHidden'

    switch @getData().type
      when "comment", "like", "mention"
        {message} = KD.singletons.socialapi
        message.byId {id: @getData().targetId}, showPost
      when "follow"        then router.handleRoute "/#{@actors[0].profile.nickname}"
      when "join", "leave" then return


  initializeReadState: ->

    if @getData().glanced
    then @unsetClass 'unread'
    else @setClass 'unread'


  fetchActors: ->

    @actors         = []
    options         = @getOptions()
    {latestActors}  = @getData()
    constructorName = 'JAccount'
    origins         = latestActors.map (id) -> {id, constructorName}

    new Promise (resolve, reject) =>
      KD.remote.cacheable origins, (err, actors) =>
        return reject err if err?
        @actors = actors
        @participants = new options.linkGroupClass {group: actors}
        @avatar       = new options.avatarClass
          size     :
            width  : 24
            height : 24
          origin   : @actors[0]
        resolve()


  getLatestTimeStamp: -> @getData().updatedAt


  getActionPhrase: -> actionPhraseMap[@getData().type]


  getActivityName: -> activityNameMap[@getData().type]


  getActivityPlot: ->

    new Promise (resolve, reject) =>
      data = @getData()
      adjective = ""
      if data.type in ['comment', 'like', 'mention']
        {message} = KD.singletons.socialapi
        message.byId {id: data.targetId}, (err, message) =>

          return reject err  if err or not message

          KD.remote.cacheable 'JAccount', message.account._id, (err, origin) =>
            return reject err  if err or not origin

            isMine     = message.account._id is KD.whoami().getId()
            isTheirOwn = @actors.length is 1 and @actors[0].getId() is origin.getId()

            adjective = if isMine then "your"
            else if isTheirOwn then "their own"
            else "#{KD.utils.getFullnameFromAccount origin}'s"

            @activityPlot.updatePartial "#{adjective} #{@getActivityName()}"
            resolve()
      else
        @activityPlot.updatePartial "#{@getActivityName()}"
        resolve()



  pistachio: ->
    """
    <div class='avatar-wrapper fl'>
      {{> @avatar}}
    </div>
    <div class='right-overflow fl'>
      {{> @participants}}
      {{  @getActionPhrase #(dummy)}}
      {{> @activityPlot}}
      {{> @timeAgoView}}
    </div>
    """


