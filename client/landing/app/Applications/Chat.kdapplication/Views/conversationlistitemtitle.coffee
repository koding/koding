class ChatConversationListItemTitle extends JView

  constructor:(options = {},data)->
    options.cssClass = 'chat-contact-list-item-title'
    super

    @avatar = new AvatarView {
      size    : {width: 30, height: 30}
      origin  : data
    }

  pistachio:->
    """
      <div class='avatar-wrapper fl'>
        {{> @avatar}}
      </div>
      <div class='right-overflow'>
        <h3>{{#(profile.firstName)+' '+#(profile.lastName)}}</h3>
      </div>
    """
