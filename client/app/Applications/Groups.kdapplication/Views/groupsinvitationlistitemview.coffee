class GroupsInvitationListItemView extends KDListItemView

  constructor:(options = {}, data)->
    options.cssClass = 'formline clearfix'
    options.type     = 'invitation-request'

    super options, data

    @avatar      = new AvatarStaticView
      size :
        width  : 40
        height : 40
    @profileLink = new KDCustomHTMLView
      tagName : 'span'
      partial : @getData().email

    if @getData().koding?.username
      @profileLink = new ProfileLinkView {}
      KD.remote.cacheable @getData().koding.username, (err, [account])=>
        @avatar.setData account
        @avatar.render()
        @profileLink.setData account
        @profileLink.render()

    @approveButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Approve'
      icon        : yes
      iconClass   : 'approve'
      callback    : =>
        @getData().approve (err)=>
          @updateButtons err, 'approved'

    @declineButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Decline'
      icon        : yes
      iconClass   : 'decline'
      callback    : =>
        @getData().declineInvitation (err)=>
          @updateButtons err, 'declined'

    @deleteButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Delete'
      icon        : yes
      iconClass   : 'decline'
      callback    : =>
        @getData().deleteInvitation (err)=>
          @updateButtons err, 'deleted'

    @statusText    = new KDCustomHTMLView
      partial     : '<span class="icon"></span><span class="title"></span>'
      cssClass    : 'status hidden'

  decorateButtons:->
    @approveButton.hide()
    @declineButton.hide()
    @deleteButton.hide()

    if @getData().status is 'pending'
      @approveButton.show()
      @declineButton.show()
    else if @getData().status is 'sent'
      @deleteButton.show()

  decorateStatus:->
    @statusText.setClass @getData().status
    @statusText.$('span.title').html @getData().status.capitalize()
    @statusText.unsetClass 'hidden'

  updateButtons:(err, expectedStatus)->
    if err
      return new KDNotificationView title:'An error occurred. Please try again later'

    @getData().status = expectedStatus

    @decorateStatus()
    @decorateButtons()
    @getDelegate().getDelegate().emit 'UpdatePendingCount'

  viewAppended:->
    JView::viewAppended.call this
    @decorateStatus()  unless @getData().status is 'pending'
    @decorateButtons()

  pistachio:->
    {status} = @getData()
    """
    <section>
      <div class="buttons">
        {{> @approveButton}} {{> @declineButton}} {{> @deleteButton}}
      </div>
      {{> @statusText}}
      <span class="avatar">{{> @avatar}}</span>
      <div class="details">
        {{> @profileLink}}
        <div class="requested-at">{{(new Date #(requestedAt)).format('mm/dd/yy')}}</div>
      </div>
    </section>
    """
