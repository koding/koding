class GroupsInvitationRequestsView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'member-related'
    super options, data

    @getData().fetchMembershipPolicy (err, @policy)=>
      @addSubView tabHandleContainer = new KDCustomHTMLView
      @addSubView @tabView = new GroupsInvitationRequestsTabView {
        delegate           : this
        tabHandleContainer
      }, data

    @on 'SearchInputChanged', (value)=>
      console.log @tabView.getActivePane().mainView
      @tabView.getActivePane().mainView.emit 'SearchInputChanged', value

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
      callback          : (formData)=>
        KD.remote.api.JInvitation.createMultiuse formData,
          @modalCallback.bind this, @inviteByEmail
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
      callback         : ({emails})=>
        @getData().inviteByEmails emails, @modalCallback.bind this, @inviteByEmail
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
    subject = if @policy.approvalEnabled then 'Membership' else 'Invitation'
    @bulkApprove = @showModalForm
      title            : "Bulk Approve #{subject} Requests"
      callback         : ({count})=>
        @getData().sendSomeInvitations count,
          @modalCallback.bind this, @bulkApprove
      content          : "<div class='modalformline'>Enter how many of the pending #{subject.toLowerCase()} requests you want to approve:</div>"
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

  modalCallback:(modal, err)->
    form = modal.modalTabs.forms.invite
    form.buttons.Send.hideLoader()
    @tabView.getActivePane().subViews.first.refresh()
    if err
      unless Array.isArray err or form.fields.report
        return @showErrorMessage err
      else
        form.fields.report.show()
        scrollView = form.fields.report.subViews.first.subViews.first
        err.forEach (errLine)->
          errLine = if errLine?.message then errLine.message else errLine
          scrollView.setPartial "#{errLine}<br/>"
        return scrollView.scrollTo top:scrollView.getScrollHeight()

    new KDNotificationView title:'Invitation sent!'
    modal.destroy()

  showErrorMessage:(err)->
    warn err
    new KDNotificationView
      title    : if err.name is 'KodingError' then err.message else 'An error occured! Please try again later.'
      duration : 2000


class GroupsInvitationCodesTabPaneView extends KDView

  setStatusesByResolvedSwitch:(state)->
  refresh:->
