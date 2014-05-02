class NewNotificationListItem extends KDListItemView

  activityNameMap =
    comment : "status."
    like    : "status."
    follow  : "started following you."
    join    : "your group"
    leave   : "your group"

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

  constructor:(options = {}, data)->

    options.tagName        or= "li"
    options.linkGroupClass or= LinkGroup
    options.avatarClass    or= AvatarView

    super options, data

    @participants = new KDCustomHTMLView
    @avatar = new KDCustomHTMLView

    # if @snapshot.anchor.constructorName is "JGroup"
    #   @interactedGroups = new options.linkGroupClass
    #     itemClass : GroupLinkView
    #     group     : [@snapshot.anchor.data]
    # else
    @interactedGroups = new KDCustomHTMLView

    @activityPlot = new KDCustomHTMLView tagName: "span"
    @timeAgoView  = new KDTimeAgoView null, @getLatestTimeStamp @getData().dummy


  fetchActors: ->
    @actors = []
    options = @getOptions()
    {latestActors} = @getData()
    promises = latestActors.map (actorId) =>
      new Promise (resolve, reject) =>
        KD.remote.api.JAccount.one socialApiId: actorId, (err, actor) =>
          return reject err  if err
          @actors.push actor
          resolve()

    Promise.all(promises).then =>
      @participants = new options.linkGroupClass {group:@actors}
      @avatar       = new options.avatarClass
        size     :
          width  : 40
          height : 40
        origin   : @actors[0]

    .catch (err) ->
      warn err


  viewAppended: ->
    promises = []
    promises.push @fetchActors()
    promises.push @getActivityPlot()

    Promise.all(promises).then =>
      @setTemplate @pistachio()
      @template.update()
    .catch (err) ->
      warn err


  pistachio:->
    """
      <div class='avatar-wrapper fl'>
        {{> @avatar}}
      </div>
      <div class='right-overflow'>
        <p>{{> @participants}} {{@getActionPhrase #(dummy)}} {{> @activityPlot}} {{> @interactedGroups}}</p>
        <footer>
          {{> @timeAgoView}}
        </footer>
      </div>
    """


  getLatestTimeStamp:->
    return @getData().updatedAt


  getActionPhrase:->
    {type} = @getData()
    actionPhraseMap[type]


  getActivityName:->
    return activityNameMap[@getData().type]

  getActivityPlot:->
    new Promise (resolve, reject)=>
      data = @getData()
      adjective = ""
      switch data.type
        when "comment", "like"
          KD.remote.api.SocialMessage.fetch {id: data.targetId}, (err, message)=>
            return reject err  if err or not message
            KD.remote.api.JAccount.one socialApiId: message.accountId, (err, origin)=>
              return reject err  if err or not origin

              adjective = if message.accountId is KD.whoami()?.socialApiId then "your"
              else if @actors.length == 1 and @actors[0].id is origin.getId() then "their own"
              else
                originatorName = KD.utils.getFullnameFromAccount origin
                "#{originatorName}'s"

              @activityPlot.updatePartial "#{adjective} #{@getActivityName()}"
              resolve()
        else
          @activityPlot.updatePartial "#{@getActivityName()}"
          resolve()



  click:->
    showPost = (err, post)->
      if post
        groupSlug = if post.group is "koding" then "" else "/#{post.group}"
        KD.getSingleton('router').handleRoute "#{groupSlug}/Activity/#{post.slug}", state:post

      else
        new KDNotificationView
          title : "This post has been deleted!"
          duration : 1000

    switch @getTargetName()
      when "SocialMessage"
        KD.remote.api.SocialMessage.fetch id: @getData().targetId, showPost
      when "JAccount"
        KD.getSingleton('router').handleRoute "/#{@actors[0].profile.nickname}"
      when "JGroup"
        return
        # do nothing