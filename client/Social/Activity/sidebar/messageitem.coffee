class SidebarMessageItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type     = 'member'
    options.cssClass = 'kdlistitemview-sidebar-item'
    options.route    = "Message/#{data.id}"

    super options, data

    data = @getData()

    for account in data.participantsPreview when account._id isnt KD.whoami().getId()
      origin = constructorName : 'JAccount', id : account._id
      break

    @actor = new ProfileTextView {origin}

    # we need a multiple avatarview here
    @avatar = new AvatarStaticView
      size       : width : 30, height : 30
      cssClass   : "avatarview"
      showStatus : yes
      origin     : origin


  pistachio: ->
    """
    {{> @avatar}}{{> @actor}}
    {span.user-numbers{ #(lastMessage.body)}}
    {{> @unreadCount}}
    """
