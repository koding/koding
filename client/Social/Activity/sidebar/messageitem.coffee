class SidebarMessageItem extends SidebarItem

  constructor: (options = {}, data) ->

    options.type     = "member"
    options.cssClass = "kdlistitemview-sidebar-item"

    super options, data

    data = @getData()

    @avatar = new AvatarView
      size       : width : 30, height : 30
      cssClass   : "avatarview"
      showStatus : yes
    , KD.whoami()

    @actor = new ProfileTextView {}, KD.whoami()

    @lastMessage = new KDCustomHTMLView
      cssClass  : 'user-numbers'
      pistachio : "{{ #(body)}}"
    , data


  viewAppended:->
    @addSubView @avatar
    @addSubView @actor
    @addSubView @lastMessage
