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
    """{{> @avatar}} {{> @actor}} followed {{> @object}}"""

class ActivityTickerLikeItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target, subject} = data

    @avatar    = new AvatarView
      size     : width: 28, height: 28
      cssClass : "avatarview"
    , source

    @liker    = new ProfileLinkView null, source
    @origin   = new ProfileLinkView null, target
    @subj     = new @itemLinkViewClassMap[subject.bongo_.constructorName] null, subject



  pistachio: ->
    {source, target, subject} = @getData()

    # i did something
    if  source.getId() is KD.whoami().getId()
      # if user liked his/her post
      if source.getId() is target.getId() then \
        return "{{> @avatar}} You liked your {{> @subj}}"
      else
        return "{{> @avatar}} You liked {{> @origin}}'s {{> @subj}}"

    # someone did something to you
    if target.getId() is KD.whoami().getId() then \
      return "{{> @avatar}} {{> @liker}} liked your {{> @subj}}"

    # if user liked his/her post
    if source.getId() is target.getId() then \
      return "{{> @avatar}} {{> @liker}} liked their {{> @subj}}"

    # rest
    return "{{> @avatar}} {{> @liker}} liked {{> @origin}}'s {{> @subj}}"

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
    """{{> @avatar}} {{> @actor}} became a member"""

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
    """{{> @avatar}} {{> @actor}} installed {{> @object}}"""

class ActivityTickerItem extends KDListItemView
  itemClassMap =
    follower   : ActivityTickerFollowItem
    like       : ActivityTickerLikeItem
    member     : ActivityTickerMemberItem
    user       : ActivityTickerAppUserItem

  constructor: (options = {}, data) ->
    options.type = "activity-ticker-item"
    super options, data

  viewAppended: ->
    data = @getData()
    {as} = data
    itemClass = itemClassMap[as]

    if itemClass
    then @addSubView new itemClass null, data
    else @destroy()
