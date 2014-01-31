class ActivityTickerBaseItem extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "action", options.cssClass
    super options, data

  pistachio: -> ""

  itemLinkViewClassMap :
    JAccount           : ProfileLinkView
    JNewApp            : AppLinkView
    JTag               : TagLinkView
    JGroup             : GroupLinkView
    JNewStatusUpdate   : ActivityLinkView
    JComment           : ActivityLinkView

class ActivityTickerFollowItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    # rels are flipped here
    {source, target} = data

    @avatar    = new AvatarView
      size     : width: 30, height: 30
      cssClass : "avatarview"
    , target

    @actor    = new ProfileLinkView null, target
    @object   = new @itemLinkViewClassMap[source.bongo_.constructorName] null, source

  pistachio: ->
    {target} = @getData()

    # if current user did the activity
    if target.getId() is KD.whoami().getId()
      return "{{> @avatar}} <div class='text-overflow'>You followed {{> @object}}</div>"

    return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} followed {{> @object}}</div>"

class ActivityTickerLikeItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target, subject} = data

    @avatar    = new AvatarView
      size     : width: 30, height: 30
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
        return "{{> @avatar}} <div class='text-overflow'>You #{activity} your {{> @subj}}</div>"
      else
        return "{{> @avatar}} <div class='text-overflow'>You #{activity} {{> @origin}}'s {{> @subj}}</div>"

    # someone did something to you
    if target.getId() is KD.whoami().getId() then \
      return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} #{activity} your {{> @subj}}</div>"

    # if user liked his/her post
    if source.getId() is target.getId() then \
      return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} #{activity} their {{> @subj}}</div>"

    # rest
    return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} #{activity} {{> @origin}}'s {{> @subj}}</div>"


class ActivityTickerMemberItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {target} = data

    @avatar    = new AvatarView
      size     : width: 30, height: 30
      cssClass : "avatarview"
    , target

    @actor    = new ProfileLinkView null, target

  pistachio: ->
    {target} = @getData()
    # if current user did the activity
    if target.getId() is KD.whoami().getId()
      return "{{> @avatar}} <div class='text-overflow'>You became a member</div>"

    return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} became a member</div>"

class ActivityTickerAppUserItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target} = data

    @avatar    = new AvatarView
      size     : width: 30, height: 30
      cssClass : "avatarview"
    , target

    @actor    = new ProfileLinkView null, target
    @object   = new AppLinkView     null, source

  pistachio: ->
    {target} = @getData()
    if target.getId() is KD.whoami().getId()
      return "{{> @avatar}} <div class='text-overflow'>You installed {{> @object}}</div>"

    return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} installed {{> @object}}</div>"

class ActivityTickerCommentItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target, object, subject} = data

    @avatar    = new AvatarView
      size     : width: 30, height: 30
      cssClass : "avatarview"
    , source

    @actor    = new ProfileLinkView null, source
    @origin   = new ProfileLinkView null, target
    @subj     = new ActivityLinkView null, object

  pistachio: ->
    {source, target, subject} = @getData()
    activity = "commented on"
    #another copy/paste. this must be changed
    # i did something
    if  source.getId() is KD.whoami().getId()
      # if user commented his/her post
      if source.getId() is target.getId() then \
        return "{{> @avatar}} <div class='text-overflow'>You #{activity} your {{> @subj}}</div>"
      else
        return "{{> @avatar}} <div class='text-overflow'>You #{activity} {{> @subj}}</div>"

    # someone did something to you
    if target.getId() is KD.whoami().getId() then \
      return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} #{activity} your {{> @subj}}</div>"

    # if user commented his/her post
    if source.getId() is target.getId() then \
      return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} #{activity} their {{> @subj}}</div>"

    # rest
    return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} #{activity} {{> @origin}}'s {{> @subj}}</div>"

class ActivityTickerStatusUpdateItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target} = data

    @avatar    = new AvatarView
      size     : width: 30, height: 30
      cssClass : "avatarview"
    , target

    @actor = new ProfileLinkView null, target
    @subj  = new ActivityLinkView null, source

  pistachio: ->
    {source, target} = @getData()
    if target.getId() is KD.whoami().getId()
      return "{{> @avatar}} <div class='text-overflow'>You posted {{> @subj}}</div>"

    return "{{> @avatar}} <div class='text-overflow'>{{> @actor}} posted {{> @subj}}</div>"


class ActivityTickerUserCommentItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data
    {@source, @target} = data

    @avatar    = new AvatarView
      size     : width: 30, height: 30
      cssClass : "avatarview"
    , @target

    @origin   = new ProfileLinkView null, @target
    @subj     = new ActivityLinkView null, @source

  pistachio: ->
    if @target.getId() is KD.whoami().getId()
      "{{> @avatar}} <div class='text-overflow'>You commented on {{> @subj}} </div>"
    else
      "{{> @avatar}} <div class='text-overflow'> {{> @origin}} commented on {{> @subj}} </div>"


class ActivityTickerItem extends KDListItemView
  itemClassMap =
    "JGroup_member_JAccount"              : ActivityTickerMemberItem
    "JAccount_like_JAccount"              : ActivityTickerLikeItem
    "JTag_follower_JAccount"              : ActivityTickerFollowItem
    "JAccount_follower_JAccount"          : ActivityTickerFollowItem
    "JNewApp_user_JAccount"               : ActivityTickerAppUserItem
    "JAccount_reply_JAccount"             : ActivityTickerCommentItem
    "JNewStatusUpdate_author_JAccount"    : ActivityTickerStatusUpdateItem
    "JNewStatusUpdate_commenter_JAccount" : ActivityTickerUserCommentItem

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
    classKey = "#{source?.bongo_?.constructorName}_#{as}_#{target?.bongo_?.constructorName}"
    return itemClassMap[classKey]

class ActiveTopicItemView extends KDListItemView
  constructor: (options = {}, data) ->
    options.type = "activity-ticker-item"
    super options, data

    @tag = new TagLinkView {}, data
    @followButton = new FollowButton
      title          : "follow"
      icon           : yes
      stateOptions   :
        unfollow     :
          title      : "unfollow"
          cssClass   : 'following-topic'
      dataType       : 'JTag'
    , data

  viewAppended:->
    @addSubView @tag
    @addSubView @followButton

    @addSubView tagInfo = new KDCustomHTMLView
      cssClass          : "tag-info clearfix"

    @getData().fetchLastInteractors {}, =>
      randomFollowers = arguments[1]
      for user in randomFollowers
        tagInfo.addSubView new AvatarView
          size: { width: 19, height: 19 }
        , user

      { followers: followerCount } = @getData().counts

      tagInfoPartial = "new topic"

      if followerCount > 0
        tagInfoPartial = "+#{followerCount} #{if followerCount is 1 then 'is' else 'are'} following"

      tagInfo.addSubView new KDCustomHTMLView
        tagName   : "span"
        cssClass  : "total-following"
        partial   : tagInfoPartial
