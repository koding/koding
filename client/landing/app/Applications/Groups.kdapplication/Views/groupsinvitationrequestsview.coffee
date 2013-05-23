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

    @createMultiuseButton = new KDButtonView
      title    : 'Create invitation code'
      cssClass : 'clean-gray'
      callback : @bound 'showMultiuseModal'
    @inviteByEmailButton = new KDButtonView
      title    : 'Invite by Email'
      cssClass : 'clean-gray'
      callback : @bound 'showInviteByEmailModal'
    @inviteByUsernameButton = new KDButtonView
      title    : 'Invite by Username'
      cssClass : 'clean-gray'
      callback : @bound 'showInviteByUsernameModal'
    @batchApproveButton = new KDButtonView
      title    : 'Batch Approve Requests'
      cssClass : 'clean-gray'
      callback : @bound 'showBatchApproveModal'

    @refresh()
    @utils.defer =>
      @parent.on 'NewInvitationActionArrived', @bound 'refresh'

  fetchAndPopulate:(controller, removeAllItems=no)->
    controller.showLazyLoader()
    controller.setLastTimestamp null if removeAllItems
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
    @updateCurrentState()
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
    listView.on 'UpdateCurrentState', @bound 'updateCurrentState'

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


  createMultiuseInvitation: (formData) ->
    KD.remote.api.JInvitation.createMultiuse formData, ->
      console.log {arguments}

  showMultiuseModal:->
    modal = new KDModalViewWithForms
      title                   : "Create a multiuse invitation code"
      tabs                    :
        forms                 :
          createInvitation    :
            callback          : @bound 'createMultiuseInvitation'
            buttons           :
              Save            :
                itemClass     : KDButtonView
                type          : 'submit'
                loader        :
                  color       : '#444444'
                  diameter    : 12
              Cancel          :
                style         : 'modal-cancel'
                callback      : -> modal.destroy()
            fields            :
              invitationCode  :
                label         : "Invitation code"
                itemClass     : KDInputView
                name          : "code"
                placeholder   : "Enter a creative invitation code!"
              maxUses         :
                label         : "Maximum uses"
                itemClass     : KDInputView
                name          : "maxUses"
                placeholder   : "How many people can redeem this code?"


    form = modal.modalTabs.forms.createInvitation
    form.on 'FormValidationFailed', => form.buttons.Send.hideLoader()

    return modal

  showModalForm:(options)->
    modal = new KDModalViewWithForms
      cssClass               : options.cssClass
      title                  : options.title
      content                : options.content
      overlay                : yes
      width                  : options.width or 400
      height                 : options.height or 'auto'
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
                callback     : -> modal.destroy()
            fields           : options.fields

    form = modal.modalTabs.forms.invite
    form.on 'FormValidationFailed', => form.buttons.Send.hideLoader()

    return modal

  showInviteByUsernameModal:->
    @inviteByUsername = @showModalForm
      cssClass         : 'invite-by-username'
      title            : 'Invite by Username'
      callback         : @emit.bind @, 'InviteByUsername'
      fields           :
        recipient      :
          label        : 'Username'
          type         : 'hidden'

    recipientField = @inviteByUsername.modalTabs.forms.invite.fields.recipient
    recipientsWrapper = new KDView
      cssClass: 'completed-items'

    @inviteByUsername.on 'AutoCompleteNeedsMemberData', (event)=>
      {callback,blacklist,inputValue} = event
      @fetchBlacklistForInviteByUsernameModal (ids)->
        blacklist.push id for id in ids
        KD.remote.api.JAccount.byRelevance inputValue, {blacklist}, (err,accounts)->
          callback accounts

    recipient = new KDAutoCompleteController
      name                : 'recipient'
      itemClass           : InviteByUsernameAutoCompleteItemView
      selectedItemClass   : InviteByUsernameAutoCompletedItemView
      outputWrapper       : recipientsWrapper
      form                : @inviteByUsername.modalTabs.forms.invite
      itemDataPath        : 'profile.nickname'
      listWrapperCssClass : 'users'
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in recipient.getSelectedItemData())
        @inviteByUsername.emit 'AutoCompleteNeedsMemberData', {inputValue,blacklist,callback}

    recipientField.addSubView recipient.getView()
    recipientField.addSubView recipientsWrapper

  showInviteByEmailModal:->
    @inviteByEmail = @showModalForm
      title            : 'Invite by Email'
      callback         : @emit.bind @, 'InviteByEmail'
      fields           :
        emails         :
          label        : 'Emails'
          type         : 'textarea'
          cssClass     : 'emails-input'
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
      content          : "<div class='modalformline'>Enter how many of the pending requests you want to approve:</div>"
      fields           :
        count          :
          label        : 'No. of requests'
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
      {{> @createMultiuseButton}} {{> @batchApproveButton}}
      {{> @inviteByEmailButton}} {{> @inviteByUsernameButton}}
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

  fetchBlacklistForInviteByUsernameModal:(callback)->
    unless @usernameBlacklist
      @usernameBlacklist = []
      @getData().fetchInvitationRequests
        targetOptions:selector:
          'koding.username': {$exists:1},
          status: $not:$in :['declined','ignored']
      , (err, requests)=>
        unless err
          @usernameBlacklist.push request.getId() for request in requests
          @getData().fetchMembers (err, members)=>
            unless err
              @usernameBlacklist.push member.getId() for member in members
            callback @usernameBlacklist
    else
      callback @usernameBlacklist

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

class InviteByUsernameAutoCompleteItemView extends KDAutoCompleteListItemView
  constructor:(options, data)->
    options.cssClass = "clearfix member-suggestion-item"
    super
    userInput = options.userInput or @getDelegate().userInput
    @avatar = new AutoCompleteAvatarView {},data
    @profileLink = new AutoCompleteProfileTextView {userInput, shouldShowNick: yes},data

  pistachio:->
    """
      <span class='avatar'>{{> @avatar}}</span>
      {{> @profileLink}}
    """

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  partial:()-> ''

class InviteByUsernameAutoCompletedItemView extends KDAutoCompletedItem
  constructor:(options, data)->
    options.cssClass = "clearfix"
    super
    @avatar = new AutoCompleteAvatarView {size : width : 16, height : 16},data
    @profileText = new AutoCompleteProfileTextView {},data

  pistachio:->
    """
      <span class='avatar'>{{> @avatar}}</span>
      {{> @profileText}}
    """

  viewAppended:->
    super()
    @setTemplate @pistachio()
    @template.update()

  partial:()-> ''