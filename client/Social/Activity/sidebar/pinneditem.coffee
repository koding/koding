class SidebarPinnedItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.type     = "member"
    options.cssClass = "kdlistitemview-sidebar-item"

    super options, data

    data = @getData()

    origin =
      id              : data.account._id
      constructorName : data.account.constructorName

    @avatar = new AvatarView {
      size       : width : 30, height : 30
      cssClass   : "avatarview"
      showStatus : yes
      origin
    }

    @actor = new ProfileTextView {origin}


  pistachio: ->
    """
    {{> @avatar}}{{> @actor}}
    {span.user-numbers{ #(body)}}
    """
