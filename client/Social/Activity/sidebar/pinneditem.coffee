class SidebarPinnedItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    {slug}           = data
    options.route    = "Post/#{slug}"
    options.type     = 'member'
    options.cssClass = 'kdlistitemview-sidebar-item conversation'

    super options, data

    data = @getData()

    origin =
      id              : data.account._id
      constructorName : data.account.constructorName

    @avatar = new AvatarStaticView {
      size       : width : 30, height : 30
      cssClass   : "avatarview"
      showStatus : yes
      origin
    }

    @actor = new ProfileTextView {origin}


  pistachio: ->
    { body } = @getData()
    { applyMarkdown, stripTags } = KD.utils

    body = stripTags applyMarkdown body
    """
    {{> @avatar}}{{> @actor}}
    <span class="user-numbers">#{body}</span>
    {{> @unreadCount}}
    """
