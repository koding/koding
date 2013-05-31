class GroupsInvitationListItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass = 'formline clearfix'
    options.type     = 'invitation-request'

    super

    data = @getData()

    @avatar      = new AvatarStaticView
      size :
        width  : 40
        height : 40
    @profileLink = new KDCustomHTMLView 
      tagName : 'span'
      partial : data.email

    if data.koding?.username
      @profileLink = new ProfileLinkView {}
      KD.remote.cacheable data.koding.username, (err, [account])=>
        @avatar.setData account
        @avatar.render()
        @profileLink.setData account
        @profileLink.render()

  viewAppended:->
    JView::viewAppended.call this

  pistachio:->
    {status} = @getData()
    """
    <section>
      <div class="status #{status}"><span class="icon"></span><span class="title">#{status.capitalize()}</span></div>
      <span class="avatar">{{> @avatar}}</span>
      <div class="details">
        {{> @profileLink}}
        <div class="requested-at">{{(new Date #(requestedAt)).format('mm/dd/yy')}}</div>
      </div>
    </section>
    """
