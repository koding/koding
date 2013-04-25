class GroupsInvitationRequestsView extends GroupsRequestView

  constructor:(options, data)->
    options.cssClass = 'groups-invitation-request-view'

    super

    group = @getData()
    @currentState = new KDView cssClass: 'formline'
    @invitationTypeFilter = options.invitationTypeFilter ? ['basic approval','invitation']

    [@penRequestsListController, @pendingRequestsList]        = @preparePendingRequestsList()
    [@penInvitationsListController, @pendingInvitationsList]  = @preparePendingInvitationsList()
    [@resRequestsListController, @resolvedRequestsList]       = @prepareResolvedRequestsList()
    [@resInvitationsListController, @resolvedInvitationsList] = @prepareResolvedInvitationsList()

    @inviteByEmailButton = new KDButtonView
      title    : 'Invite by Email'
      cssClass : 'clean-gray'
      callback : @bound 'showInviteByEmailModal'
    @inviteByUsernameButton = new KDButtonView
      title    : 'Invite by Username'
      cssClass : 'clean-gray'
      callback : @bound 'showInviteByUsernameModal'
    @batchInviteButton = new KDButtonView
      title    : 'Batch Invite'
      cssClass : 'clean-gray'
      callback : @bound 'showBatchInviteModal'
    @batchApproveButton = new KDButtonView
      title    : 'Batch Approve Requests'
      cssClass : 'clean-gray'
      callback : @bound 'showBatchApproveModal'

    @prepareBulkInvitations()
    @refresh()
    @utils.defer =>
      @parent.on 'NewInvitationActionArrived', @bound 'refresh'

  fetchAndPopulate:(controller, removeAllItems=no)->
    controller.showLazyLoader()
    @fetchSomeRequests @invitationTypeFilter, controller.getStatuses(), controller.getLastTimestamp(), (err, requests)=>
      controller.hideLazyLoader()
      return warn err if err
      controller.removeAllItems() if removeAllItems
      controller.instantiateListItems requests 
      if requests?.length > 0
        controller.setLastTimestamp requests.last.timestamp_
        controller.emit 'teasersLoaded', requests.length
      else
        controller.emit 'noItemsFound'

  refresh:->
    @fetchAndPopulate @penRequestsListController, yes
    @fetchAndPopulate @penInvitationsListController, yes
    @fetchAndPopulate @resRequestsListController, yes
    @fetchAndPopulate @resInvitationsListController, yes

  prepareList:(options)->
    controller = new InvitationRequestListController options

    if options.isModal
      controller.on 'LazyLoadThresholdReached', @fetchAndPopulate.bind this, controller
      controller.on 'teasersLoaded', =>
        unless controller.scrollView.hasScrollBars()
          @fetchAndPopulate controller
    else
      controller.on 'teasersLoaded', (count)=>
        controller.moreLink?.show() if count >= @requestLimit
      controller.on 'ShowMoreRequested', @showListModal.bind this, options

    return [controller, controller.getView()]

  showListModal:({prepareMethod, title, width})->
    [controller, view] = @[prepareMethod] yes
    @fetchAndPopulate controller, yes

    modal = new GroupsInvitationRequestsModalView {title, width}
    modal.addSubView controller.getView()
    modal._windowDidResize()

  preparePendingRequestsList:(isModal=no)->
    [controller, view] = @prepareList
      itemClass       : GroupsInvitationRequestListItemView
      statuses        : 'pending'
      isModal         : isModal
      prepareMethod   : 'preparePendingRequestsList'
      title           : 'Pending Requests'
      noItemFound     : 'No pending requests.'
      noMoreItemFound : 'No more pending requests found.'
      width           : 400

    listView = controller.getListView()
    @forwardEvent listView, 'RequestIsApproved'
    @forwardEvent listView, 'RequestIsDeclined'

    return [controller, view]

  preparePendingInvitationsList:(isModal=no)->
    @prepareList
      itemClass       : GroupsInvitationRequestListItemView
      statuses        : 'sent'
      isModal         : isModal
      prepareMethod   : 'preparePendingInvitationsList'
      title           : 'Pending Invitations'
      noItemFound     : 'No pending invitations.'
      noMoreItemFound : 'No more pending invitations found.'

  prepareResolvedRequestsList:(isModal=no)->
    @prepareList
      itemClass       : GroupsInvitationListItemView
      statuses        : ['approved', 'declined']
      isModal         : isModal
      prepareMethod   : 'prepareResolvedRequestsList'
      title           : 'Resolved Requests'
      noItemFound     : 'No resolved requests.'
      noMoreItemFound : 'No more resolved requests found.'

  prepareResolvedInvitationsList:(isModal=no)->
    @prepareList
      itemClass       : GroupsInvitationListItemView
      statuses        : ['accepted', 'ignored']
      isModal         : isModal
      prepareMethod   : 'prepareResolvedInvitationsList'
      title           : 'Resolved Invitations'
      noItemFound     : 'No resolved invitations.'
      noMoreItemFound : 'No more resolved invitations found.'

  showModalForm:(options)->
    modal = new KDModalViewWithForms
      title                  : options.title
      overlay                : yes
      width                  : 300
      height                 : 'auto'
      tabs                   :
        forms                :
          invite             :
            callback         : options.callback
            buttons          :
              Send           :
                itemClass    : KDButtonView
                type         : 'submit'
                loader       :
                  color      : '#444444'
                  diameter   : 12
              Cancel         :
                style        : 'modal-cancel'
                callback     : (event)=> modal.destroy()
            fields           : options.fields

    form = modal.modalTabs.forms.invite
    form.on 'FormValidationFailed', => form.buttons.Send.hideLoader()

    return modal

  showInviteByEmailModal:->
    @inviteByEmail = @showModalForm
      title              : 'Invite by Email'
      callback           : @emit.bind @, 'InviteByEmail'
      fields             :
        recipient        :
          label          : 'Email address'
          type           : 'text'
          name           : 'recipient'
          placeholder    : 'Enter an email address...'
          validate       :
            rules        :
              required   : yes
              email      : yes
            messages     :
              required   : 'An email address is required!'
              email      : 'That does not not seem to be a valid email address!'

  showInviteByUsernameModal:->
    @inviteByUsername = @showModalForm
      title            : 'Invite by Username'
      callback         : @emit.bind @, 'InviteByUsername'
      fields           :
        recipient      :
          label        : 'Username'
          type         : 'text'
          name         : 'recipient'
          placeholder  : 'Enter a user name...'
          validate     :
            rules      :
              required : yes
            messages   :
              required : 'A user name is required!'

  showBatchInviteModal:->
    @batchInvite = @showModalForm
      title            : 'Batch Invite by Email'
      callback         : @emit.bind @, 'BatchInvite'
      fields           :
        emails         :
          label        : 'Emails'
          type         : 'textarea'
          placeholder  : 'Enter each email address on a new line...'
          validate     :
            rules      :
              required : yes
            messages   :
              required : 'At least one email address required!'

  showBatchApproveModal:->
    @batchApprove = @showModalForm
      title            : 'Batch Approve Requests'
      callback         : @emit.bind @, 'BatchApproveRequests'
      fields           :
        count          :
          label        : '# of requests'
          type         : 'text'
          defaultValue : 10
          placeholder  : 'how many requests do you want to approve?'
          validate     :
            rules      :
              regExp   : /\d+/i
            messages   :
              regExp   : 'numbers only please'

  showErrorMessage:(err)->
    warn err
    new KDNotificationView 
      title    : if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
      duration : 2000

  pistachio:->
    """
    <div class="button-bar">
      {{> @batchApproveButton}} {{> @batchInviteButton}} {{> @inviteByEmailButton}} {{> @inviteByUsernameButton}}
    </div>
    <section class="formline status-quo">
      <h2>Status quo</h2>
      {{> @currentState}}
    </section>
    <div class="formline">
      <section class="formline pending">
        <h2>Pending requests</h2>
        {{> @pendingRequestsList}}
      </section>
      <section class="formline sent">
        <h2>Sent invitations</h2>
        {{> @pendingInvitationsList}}
      </section>
    </div>
    <div class="formline">
      <section class="formline resolved">
        <h2>Resolved requests</h2>
        {{> @resolvedRequestsList}}
      </section>
      <section class="formline resolved">
        <h2>Resolved invitations</h2>
        {{> @resolvedInvitationsList}}
      </section>
    </div>
    """

class GroupsInvitationRequestsModalView extends KDModalView
  constructor:(options = {}, data)->
    options.cssClass or= 'invitations-request-modal'
    options.overlay   ?= yes
    options.width    or= 400
    options.height   or= 'auto'

    super

  _windowDidResize:->
    super
    {winHeight} = @getSingleton('windowController')
    log @$('.kdmodal-content .kdscrollview')
    @$('.kdmodal-content .kdscrollview').css 'max-height', winHeight - 200
