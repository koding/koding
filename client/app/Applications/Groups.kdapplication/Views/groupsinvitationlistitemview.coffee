class GroupsInvitationListItemView extends KDListItemView
  constructor:(options, data)->
    options.cssClass = 'invitation-request formline clearfix'

    super

    invitationRequest = @getData()

    @avatar = new AvatarStaticView
      size :
        width : 40
        height : 40

    if @getData().koding
      @recipient = @getData().koding.username
      KD.remote.cacheable @recipient, (err, [account])=>
        @avatar.setData account
        @avatar.render()
    else
      @recipient = @getData().email

    @getData().on 'update', => @updateStatus()
    @updateStatus()

  updateStatus:->
    isSent = @getData().sent
    @[if isSent then 'setClass' else 'unsetClass'] 'invitation-sent'
    @inviteButton.disable()  if isSent

  viewAppended:->
    JView::viewAppended.call this

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
        <div class="username">#{@recipient}</div>
        <div class="requested-at">Requested on {{(new Date #(requestedAt)).format('mm/dd/yy')}}</div>
        <div class="is-sent">Status is <span class='status'>{{@getStatusText #(status)}}</span></div>
      </div>
    </div>
    """