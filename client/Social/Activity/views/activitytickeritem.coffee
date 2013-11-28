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

class ActivityTickerFollowItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target} = data

    @avatar    = new AvatarView
      size     : width: 28, height: 28
      cssClass : "avatarview"
    , source

    @actor    = new ProfileLinkView null, source
    @object   = new @itemLinkViewClassMap[target.bongo_.constructorName] null, target

  pistachio: ->
    """{{> @avatar}} {{> @actor}} followed {{> @object}}"""

class ActivityTickerLikeItem extends ActivityTickerBaseItem
  constructor: (options = {}, data) ->
    super options, data

    {source, target} = data

    @avatar    = new AvatarView
      size     : width: 28, height: 28
      cssClass : "avatarview"
    , target

    @actor    = new ProfileLinkView null, target
    @object   = new @itemLinkViewClassMap[source.bongo_.constructorName] null, source

  pistachio: ->
    """{{> @avatar}} {{> @actor}} liked {{> @object}}"""

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
