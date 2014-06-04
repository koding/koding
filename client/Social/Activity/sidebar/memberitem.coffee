class SidebarMemberItem extends SidebarItem

  constructor: (options = {}, data) ->

    options.hideLastMessage ?= no
    options.type             = 'member'
    options.cssClass         = 'kdlistitemview-sidebar-item'
    options.route            = "Chat/#{data.id}"

    super options, data

    account = @getData()

    @avatar = new AvatarStaticView
      size       : width : 30, height : 30
      cssClass   : "avatarview"
      showStatus : yes
    , account

    @actor = new ProfileTextView {}, account

    unless @getOption "hideLastMessage"

      account.meta.lastMessage = 'Yo yo babazillo...'

      @followersAndFollowing = new KDCustomHTMLView
        cssClass  : 'user-numbers'
        pistachio : "{{ #(meta.lastMessage)}}"
      , account

    @count = new KDCustomHTMLView
      cssClass : 'count'
      tagName  : 'cite'
      partial  : '1'

  viewAppended:->
    @addSubView @avatar
    @addSubView @actor
    @addSubView @count unless @getOption 'hideNewMessageCount'
    @addSubView @followersAndFollowing unless @getOption 'hideLastMessage'
    @addSubView @unreadCount
