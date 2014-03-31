class TeamworkTabHandleWithAvatar extends KDTabHandleView

  constructor: (options = {}, data) ->

    options.view              = new TeamworkTabHandleAvatarView options
    options.addTitleAttribute = no

    super options, data

    @avatarView = @getOption "view"

  setTitle: (title) ->
    @avatarView.title.updatePartial title

  setAccounts: (accounts) ->
    @avatarView.setAccounts accounts


class TeamworkTabHandleAvatarView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-tab-avatar-view"

    super options, data

    @accounts = []

    @addSubView @title = new KDCustomHTMLView
      cssClass   : "tw-tab-avatar-title"
      partial    : "#{options.title}"

  createAvatar: ->
    @avatar      = new AvatarStaticView
      cssClass   : "tw-tab-avatar-img"
      bind       : "mouseenter mouseleave"
      mouseenter : @bound "avatarMouseEnter"
      mouseleave : @bound "avatarMouseLeave"
      size       :
        width    : 20
        height   : 20
    , @accounts.first

    @addSubView @avatar

  avatarMouseLeave: ->
    @avatar.avatarsMenu?.destroy()

  avatarMouseEnter: ->
    offset = @avatar.$().offset()
    @avatar.avatarsMenu = new KDContextMenu
      menuWidth     : 160
      delegate      : @avatar
      treeItemClass : TeamworkAvatarContextMenuItem
      x             : offset.left - 106
      y             : offset.top + 27
      arrow         :
        placement   : "top"
        margin      : 108
      lazyLoad      : yes
    , {}

    KD.utils.defer =>
      @accounts.forEach (account) =>
        @avatar.avatarsMenu.treeController.addNode account

  removeAvatar: ->
    @avatar?.destroy()

  setAccounts: (accounts) ->
    @accounts = accounts
    if accounts.length > 0 then @createAvatar() else @removeAvatar()


class TeamworkAvatarContextMenuItem extends JContextMenuItem

  constructor: (options = {}, data) ->

    super options, data

    @avatar = new AvatarStaticView
      size     :
        width  : 20
        height : 20
      cssClass : "tw-tab-avatar-img-context"
    , @getData()

  pistachio: ->
    """
      {{> @avatar}}
      #{@getData().profile.nickname}
    """
