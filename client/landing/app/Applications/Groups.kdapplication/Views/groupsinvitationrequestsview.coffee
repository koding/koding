class GroupsInvitationRequestsView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'member-related'
    super options, data

    @addSubView tabHandleContainer = new KDCustomHTMLView
    @addSubView @tabView = new GroupsInvitationRequestsTabView {
      delegate           : this
      tabHandleContainer
    }, data

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


class GroupsInvitationCodesTabPaneView extends KDView

  setStatusesByResolvedSwitch:(state)->
