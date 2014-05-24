class SidebarMessageItem extends SidebarItem

  constructor: (options = {}, data) ->

    options.type     = 'member'
    options.cssClass = 'kdlistitemview-sidebar-item'
    options.route    = "Message/#{data.id}"

    super options, data

    data = @getData()

    accountIds = Object.keys KD.remote.api.JAccount.cache
    origin     =
      constructorName : 'JAccount'
      id              : accountIds[KD.utils.getRandomNumber accountIds.length - 1]

    @actor = new ProfileTextView {origin}

    @avatar = new AvatarView
      size       : width : 30, height : 30
      cssClass   : "avatarview"
      showStatus : yes
      origin     : origin

    @lastMessage = new KDCustomHTMLView
      cssClass  : 'user-numbers'
      pistachio : "{{ #(body)}}"
    , data.lastMessage


  viewAppended:->
    @addSubView @avatar
    @addSubView @actor
    @addSubView @lastMessage
