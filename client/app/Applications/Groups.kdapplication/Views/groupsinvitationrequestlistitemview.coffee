class GroupsInvitationRequestListItemView extends GroupsInvitationListItemView

  constructor:(options = {}, data)->

    super

    @approveButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Approve'
      icon        : yes
      iconClass   : 'approve'
      callback    : =>
        @getDelegate().emit 'RequestIsApproved', @getData(), (err)=>
          @updateButtons err, 'approved'

    @declineButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Decline'
      icon        : yes
      iconClass   : 'decline'
      callback    : => 
        @getDelegate().emit 'RequestIsDeclined', @getData(), (err)=>
          @updateButtons err, 'declined'

    @statusText    = new KDCustomHTMLView
      partial     : '<span class="icon"></span><span class="title"></span>'
      cssClass    : 'status hidden'

  hideButtons:->
    @approveButton.hide()
    @declineButton.hide()
    @statusText.setClass @getData().status
    @statusText.$('span.title').html @getData().status.capitalize()
    @statusText.unsetClass 'hidden'

  showButtons:->
    @approveButton.show()
    @declineButton.show()

  initializeButtons:->
    if @getData().status is 'pending'
      @showButtons()
    else
      @hideButtons()

  updateButtons:(err, expectedStatus)->
    if err
      return new KDNotificationView title:'An error occurred. Please try again later'
    @getData().status = expectedStatus
    @initializeButtons()
    @getDelegate().emit 'UpdateCurrentState'

  viewAppended:->
    JView::viewAppended.call this
    @initializeButtons()

  pistachio:->
    {status} = @getData()
    """
    <section>
      {{> @statusText}}
      <div class="buttons">
        {{> @approveButton}}
        {{> @declineButton}}
      </div>
      <span class="avatar">{{> @avatar}}</span>
      <div class="details">
        {{> @profileLink}}
        <div class="requested-at">{{(new Date #(requestedAt)).format('mm/dd/yy')}}</div>
      </div>
    </section>
    """
