class SidebarMemberItem extends SidebarItem

  constructor: (options = {}, data) ->

    options.type     = "member"
    options.cssClass = "kdlistitemview-sidebar-item"

    super options, data

    account = @getData()

    @avatar = new AvatarView
      size       : width : 30, height : 30
      cssClass   : "avatarview"
      showStatus : yes
    , account

    @actor = new ProfileTextView {}, account

    account.meta.lastMessage = 'Yo yo babazillo...'

    @followersAndFollowing = new KDCustomHTMLView
      cssClass  : 'user-numbers'
      pistachio : "{{ #(meta.lastMessage)}}"
    , account


  viewAppended:->
    @addSubView @avatar
    @addSubView @actor
    @addSubView @followersAndFollowing
