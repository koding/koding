class GroupsInvitationRequestListItemView extends KDListItemView
  constructor:(options, data)->
    options.cssClass = 'invitation-request formline clearfix'

    super

    invitationRequest = @getData()

    @avatar = new AvatarStaticView
      size :
        width : 40
        height : 40

    KD.remote.cacheable @getData().koding.username, (err,account)=>
      @avatar.setData account
      @avatar.render()

    @approveButton = new KDButtonView
      cssClass  : 'cupid-green'
      title     : 'Approve'
      callback  : =>
        @getDelegate().emit 'RequestIsApproved', invitationRequest

    @declineButton = new KDButtonView
      cssClass  : 'clean-red'
      title     : 'Decline'
      callback  : =>
        @getDelegate().emit 'RequestIsDeclined', invitationRequest

    @getData().on 'update', => @updateStatus()

    @updateStatus()

  updateStatus:->
    isSent = @getData().sent
    @[if isSent then 'setClass' else 'unsetClass'] 'invitation-sent'
    @inviteButton.disable()  if isSent

  hideButtons:->
    @approveButton.hide()
    @declineButton.hide()

  showButtons:->
    @approveButton.show()
    @declineButton.show()

  initializeButtons:->
    invitationRequest = @getData()

    if invitationRequest.status is 'pending'
      @showButtons()
    else
      @hideButtons()

  viewAppended:->
    JView::viewAppended.call this
    @initializeButtons()
    @getData().on 'update', @bound 'initializeButtons'

  getStatusText:(status)->
    switch status
      when 'approved' then '✓ Approved'
      when 'pending'  then '… Pending'
      when 'sent'     then '… Sent'
      when 'declined' then '✗ Declined'

  pistachio:->
    """
    <div class="fl">
      <span class="avatar">{{> @avatar}}</span>
      <div class="request">
        <div class="username">{{#(koding.username)}}</div>
        <div class="requested-at">Requested on {{(new Date #(requestedAt)).format('mm/dd/yy')}}</div>
        <div class="is-sent">Status is <span class='status'>{{@getStatusText #(status)}}</span></div>
      </div>
    </div>
    <div class="fr">{{> @approveButton}} {{> @declineButton}}</div>
    """