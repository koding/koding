class SidebarMessageItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type     = 'member'
    options.cssClass = 'kdlistitemview-sidebar-item'
    options.route    = "Message/#{data.id}"

    super options, data

    data = @getData()

    # users can send messages to themselves and to others; if they're others
    # show their avatars, fallback to user's avatar if they're the only one
    if data.participantsPreview.length is 1
      origin = data.participantsPreview[0]
    else
      for account in data.participantsPreview when account._id isnt KD.userAccount._id
        origin = account
        break

    origin = constructorName : 'JAccount', id : origin._id

    @actor = new ProfileTextView {origin}

    # we need a multiple avatarview here
    @avatar = new AvatarStaticView
      size       : width : 24, height : 24
      cssClass   : "avatarview"
      showStatus : yes
      origin     : origin


  pistachio: -> "{{> @avatar}}{{> @actor}}{{> @unreadCount}}"
