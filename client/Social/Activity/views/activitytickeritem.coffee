class ActivityTickerBaseItem extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "action", options.cssClass
    super options, data

  pistachio: -> ""

  itemLinkViewClassMap :
    JAccount           : ProfileLinkView
    JApp               : AppLinkView
    JTag               : TagLinkView
    JGroup             : GroupLinkView
    JStatusUpdate      : ActivityLinkView
    JComment           : ActivityCommentView

class ActivityTickerFollowItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    # rels are flipped here
    {source, target} = data

    @avatar    = new AvatarView
      size     : width: 28, height: 28
      cssClass : "avatarview"
    , target

    @actor    = new ProfileLinkView null, target
    @object   = new @itemLinkViewClassMap[source.bongo_.constructorName] null, source

  pistachio: ->
    {target} = @getData()

    # if current user did the activity
    if target.getId() is KD.whoami().getId()
      return "{{> @avatar}} You followed {{> @object}}"

    return "{{> @avatar}} {{> @actor}} followed {{> @object}}"

class ActivityTickerLikeItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target, subject} = data

    @avatar    = new AvatarView
      size     : width: 28, height: 28
      cssClass : "avatarview"
    , source

    @actor    = new ProfileLinkView null, source
    @origin   = new ProfileLinkView null, target
    @subj     = new @itemLinkViewClassMap[subject.bongo_.constructorName] null, subject

  pistachio: ->
    {source, target, subject} = @getData()
    activity = "liked"
    # i did something
    if  source.getId() is KD.whoami().getId()
      # if user liked his/her post
      if source.getId() is target.getId() then \
        return "{{> @avatar}} You #{activity} your {{> @subj}}"
      else
        return "{{> @avatar}} You #{activity} {{> @origin}}'s {{> @subj}}"

    # someone did something to you
    if target.getId() is KD.whoami().getId() then \
      return "{{> @avatar}} {{> @actor}} #{activity} your {{> @subj}}"

    # if user liked his/her post
    if source.getId() is target.getId() then \
      return "{{> @avatar}} {{> @actor}} #{activity} their {{> @subj}}"

    # rest
    return "{{> @avatar}} {{> @actor}} #{activity} {{> @origin}}'s {{> @subj}}"


class ActivityTickerMemberItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {target} = data

    @avatar    = new AvatarView
      size     : width: 28, height: 28
      cssClass : "avatarview"
    , target

    @actor    = new ProfileLinkView null, target

  pistachio: ->
    {target} = @getData()
    # if current user did the activity
    if target.getId() is KD.whoami().getId()
      return "{{> @avatar}} You became a member"

    return "{{> @avatar}} {{> @actor}} became a member"

class ActivityTickerAppUserItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target} = data

    @avatar    = new AvatarView
      size     : width: 28, height: 28
      cssClass : "avatarview"
    , target

    @actor    = new ProfileLinkView null, target
    @object   = new AppLinkView     null, source

  pistachio: ->
    {target} = @getData()
    if target.getId() is KD.whoami().getId()
      return "{{> @avatar}} You installed {{> @object}}"

    return "{{> @avatar}} {{> @actor}} installed {{> @object}}"

class ActivityTickerCommentItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target, subject, object} = data

    @avatar    = new AvatarView
      size     : width: 28, height: 28
      cssClass : "avatarview"
    , source

    @actor    = new ProfileLinkView null, source
    @origin   = new ProfileLinkView null, target
    @subj     = new ActivityLinkView null, subject
    @object   = new ActivityCommentView null, object

  pistachio: ->
    {source, target, subject} = @getData()
    activity = "commented on"
    #another copy/paste. this must be changed
    # i did something
    if  source.getId() is KD.whoami().getId()
      # if user commented his/her post
      if source.getId() is target.getId() then \
        return "{{> @avatar}} You #{activity} your {{> @subj}}:{{> @object}}"
      else
        return "{{> @avatar}} You #{activity} {{> @origin}}'s {{> @subj}}:{{> @object}}"

    # someone did something to you
    if target.getId() is KD.whoami().getId() then \
      return "{{> @avatar}} {{> @actor}} #{activity} your {{> @subj}}:{{> @object}}"

    # if user commented his/her post
    if source.getId() is target.getId() then \
      return "{{> @avatar}} {{> @actor}} #{activity} their {{> @subj}}:{{> @object}}"

    # rest
    return "{{> @avatar}} {{> @actor}} #{activity} {{> @origin}}'s {{> @subj}}:{{> @object}}"

class ActivityTickerItem extends KDListItemView
  itemClassMap =
    "JGroup_member_JAccount" : ActivityTickerMemberItem
    "JAccount_like_JAccount" : ActivityTickerLikeItem
    "JTag_follower_JAccount" : ActivityTickerFollowItem
    "JApp_user_JAccount"     : ActivityTickerAppUserItem
    "JAccount_reply_JAccount": ActivityTickerCommentItem

  constructor: (options = {}, data) ->
    options.type = "activity-ticker-item"
    super options, data

  viewAppended: ->
    data = @getData()
    itemClass = @getClassName data

    if itemClass
    then @addSubView new itemClass null, data
    else @destroy()

  getClassName: (data)->
    {as, source, target} = data
    classKey = "#{source.bongo_.constructorName}_#{as}_#{target.bongo_.constructorName}"

    return itemClassMap[classKey]

class ActiveUserItemView extends KDListItemView
  constructor: (options = {}, data) ->
    options.type = "activity-ticker-item"
    super options, data

    data = @getData()

    @avatar  = new AvatarView
      size       : width: 25, height: 25
      cssClass   : "avatarview"
      showStatus : yes
    , data

    @actor = new ProfileLinkView {}, data

    unless KD.isMine data
      @followButton = new FollowButton
        style          : "solid green"
        stateOptions   :
          unfollow     :
            cssClass   : 'following-account'
        dataType       : 'JAccount'
      , data

  viewAppended:->
    @addSubView @avatar
    @addSubView @actor

    @addSubView @followButton  if @followButton

class ActiveTopicItemView extends KDListItemView
  constructor: (options = {}, data) ->
    options.type = "activity-ticker-item"
    super options, data

    @tag = new TagLinkView {}, data
    @followButton = new FollowButton
      cssClass       : 'solid green'
      stateOptions   :
        unfollow     :
          cssClass   : 'following-topic'
      dataType       : 'JTag'
    , data

  viewAppended:->
    @addSubView @tag
    @addSubView @followButton
