class GroupsInvitationListItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.cssClass = 'formline clearfix'
    options.type     = 'invitation-request'

    super options, data

    @avatar      = new AvatarStaticView
      size     :
        width  : 40
        height : 40
    @profileLink = new KDCustomHTMLView
      tagName : 'span'
      partial : @getData().email

    if @getData().username
      @profileLink = new ProfileLinkView {}
      KD.remote.cacheable @getData().username, (err, [account])=>
        @avatar.setData account
        @avatar.render()
        @profileLink.setData account
        @profileLink.render()

    @approveButton = new KDButtonView
      style       : 'solid medium green'
      title       : 'Approve'
      icon        : yes
      iconClass   : 'approve'
      testPath    : "groups-request-approve"
      callback    : =>
        @getData().approve (err)=>
          @updateButtons err, 'approved'
          @getDelegate().emit 'InvitationStatusChanged'  unless err

    @declineButton = new KDButtonView
      style       : 'solid medium light-gray'
      title       : 'Decline'
      icon        : yes
      iconClass   : 'decline'
      callback    : =>
        @getData().decline (err)=>
          @updateButtons err, 'declined'
          @getDelegate().emit 'InvitationStatusChanged'  unless err

    @deleteButton = new KDButtonView
      style       : 'solid medium red'
      title       : "Delete"
      callback    : =>
        @getData().remove (err) =>
          @updateButtons err, 'deleted'
          @getDelegate().emit 'InvitationStatusChanged'  unless err

    @statusText    = new KDCustomHTMLView
      partial     : '<span class="icon"></span>'
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
    return KD.showError err  if err

    @getData().status = expectedStatus

    @decorateStatus()
    @decorateButtons()
    @getDelegate().getDelegate().emit 'UpdatePendingCount'

  viewAppended:->
    JView::viewAppended.call this
    @decorateStatus()  unless @getData().status is 'pending'
    @decorateButtons()

  pistachio:->
    {status, requestedAt, createdAt} = @getData()
    """
    <section>
      <div class="buttons">
        {{> @approveButton}} {{> @declineButton}} {{> @deleteButton}}
      </div>
      {{> @statusText}}
      <span class="avatar">{{> @avatar}}</span>
      <div class="details">
        {{> @profileLink}}
        <div class="requested-at">{{(new Date #(requestedAt) ? #(createdAt)).format('mm/dd/yy')}}</div>
      </div>
    </section>
    """
