class GroupsInvitationRequestsView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'member-related'
    super options, data

    @addSubView @tabView = new KDTabView
      cssClass             : 'invitations-tabs'
      maxHandleWidth       : 160
      hideHandleCloseIcons : yes
    , data
    for tab, i in @getTabs()
      tab.viewOptions.data    = @getData()
      tab.viewOptions.options = delegate: this
      @tabView.addPane new KDTabPaneView(tab), i is 0

    @showResolvedView = new KDView cssClass : 'show-resolved'
    @showResolvedView.addSubView showResolvedLabelView = new KDLabelView
      title    : 'Include Resolved: '
    @showResolvedView.addSubView new KDOnOffSwitch
      label    : showResolvedLabelView
      callback : (@resolvedState)=>
        view = @tabView.getActivePane().subViews.first
        view.setStatusesByResolvedSwitch @resolvedState
        view.refresh()

    @buttonContainer = new KDView cssClass: 'button-bar'
    @tabView.getTabHandleContainer().addSubView @buttonContainer
    @addHeaderButtons()
    @tabView.on 'PaneDidShow', @bound 'decorateHeaderButtons'

  addHeaderButtons:->
    @buttonContainer.addSubView @showResolvedView
    @buttonContainer.addSubView @bulkApproveButton = new KDButtonView
      title    : 'Bulk Approve'
      cssClass : 'clean-gray'
      callback : @bound 'showBulkApproveModal'
    @buttonContainer.addSubView @inviteByEmailButton = new KDButtonView
      title    : 'Invite by Email'
      cssClass : 'clean-gray'
      callback : @bound 'showInviteByEmailModal'
    @buttonContainer.addSubView @createInvitationCodeButton = new KDButtonView
      title    : 'Create Invitation Code'
      cssClass : 'clean-gray'
      callback : @bound 'showCreateInvitationCodeModal'

    @decorateHeaderButtons()

  decorateHeaderButtons:->
    button.hide()  for button in @buttonContainer.subViews.slice 1

    switch @tabView.getActivePane().name
      when 'Membership Requests'
        @bulkApproveButton.show()
      when 'Invitations'
        @inviteByEmailButton.show()
      when 'Invitation Codes'
        @createInvitationCodeButton.show()

  getTabs:->
    [
      name        : 'Membership Requests'
      viewOptions :
        viewClass : GroupsMembershipRequestsTabPaneView
    ,
      name        : 'Invitations'
      viewOptions :
        viewClass : GroupsSentInvitationsTabPaneView
    ,
      name        : 'Invitation Codes'
      viewOptions :
        viewClass : GroupsInvitationCodesTabPaneView
    ]

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
                label        : options.submitButtonLabel or 'Send'
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

  showCreateInvitationCodeModal:->
    @createInvitationCode = @showModalForm
      title             : 'Create an Invitation Code'
      cssClass          : ''
      callback          : @emit.bind this, 'CreateInvitationCode'
      submitButtonLabel : 'Create'
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

  showInviteByEmailModal:->
    @inviteByEmail = @showModalForm
      title            : 'Invite by Email'
      cssClass         : 'invite-by-email'
      callback         : @emit.bind this, 'InviteByEmail'
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
        report         :
          itemClass    : KDScrollView
          cssClass     : 'report'

    @inviteByEmail.modalTabs.forms.invite.fields.report.hide()

  showBulkApproveModal:->
    @batchApprove = @showModalForm
      title            : 'Bulk Approve Membership Requests'
      callback         : @emit.bind this, 'BulkApproveRequests'
      content          : "<div class='modalformline'>Enter how many of the pending membership requests you want to approve:</div>"
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


class GroupsInvitationsTabPaneView extends KDView

  requestLimit: 6

  constructor:(options={}, data)->
    options.itemClass          or= GroupsInvitationListItemView
    options.resolvedStatuses   or= ['pending', 'approved', 'declined']
    options.unresolvedStatuses or= 'pending'

    super options, data

    @setStatusesByResolvedSwitch @getDelegate().resolvedState ? no

    @controller = new InvitationRequestListController options
    @listView   = @controller.getView()
    @addSubView @listView

  addListeners:->
    @controller.on 'teasersLoaded', (count)=>
      @controller.hideNoItemWidget()  if count > 0

  fetchRequests:(callback)->
    status   = @options.statuses
    status   = $in: status                 if Array.isArray status
    selector = timestamp: $lt: @timestamp  if @timestamp

    options  =
      targetOptions :
        selector    : {status}
        limit       : @requestLimit
        sort        : { requestedAt: -1 }
      options       :
        sort        : { timestamp: -1 }

    @getData().fetchInvitationRequests selector, options, callback

  fetchAndPopulate:->
    @controller.showLazyLoader no

    @fetchRequests (err, requests)=>
      @controller.hideLazyLoader()
      if err or requests.length is 0
        warn err  if err
        return @controller.emit 'noItemsFound'

      @timestamp = requests.last.timestamp_
      @controller.instantiateListItems requests
      @controller.emit 'teasersLoaded', requests.length  if requests.length is @requestLimit

  viewAppended:->
    super()
    @addListeners()
    @fetchAndPopulate()

  refresh:->
    @controller.removeAllItems()
    @timestamp = null
    @fetchAndPopulate()

  setStatusesByResolvedSwitch:(state)->
    @options.statuses = if state\
                        then @options.resolvedStatuses\
                        else @options.unresolvedStatuses


class GroupsMembershipRequestsTabPaneView extends GroupsInvitationsTabPaneView

  constructor:(options={}, data)->
    options.itemClass       or= GroupsInvitationRequestListItemView
    options.noItemFound     or= 'No requests found.'
    options.noMoreItemFound or= 'No more requests found.'

    super options, data


class GroupsSentInvitationsTabPaneView extends GroupsInvitationsTabPaneView

  constructor:(options={}, data)->
    options.resolvedStatuses   or= ['sent', 'accepted', 'ignored']
    options.unresolvedStatuses or= 'sent'
    options.noItemFound        or= 'No sent invitations found.'
    options.noMoreItemFound    or= 'No more sent invitations found.'

    super options, data


class GroupsInvitationCodesTabPaneView extends KDView

  setStatusesByResolvedSwitch:(state)->
