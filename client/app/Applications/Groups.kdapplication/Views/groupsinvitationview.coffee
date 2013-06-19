class GroupsInvitationView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'member-related'
    super options, data

    @getData().fetchMembershipPolicy (err, @policy)=>
      @addSubView tabHandleContainer = new KDCustomHTMLView
      @addSubView @tabView = new GroupsInvitationTabView {
        delegate           : this
        tabHandleClass     : GroupTabHandleView
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
    KD.remote.api.JInvitation.suggestCode (err, suggestedCode)=>
      return @showErrorMessage err  if err
      @createInvitationCode = @showModalForm
        title             : 'Create an Invitation Code'
        cssClass          : 'create-invitation-code'
        callback          : (formData)=>
          KD.remote.api.JInvitation.createMultiuse formData,
            @modalCallback.bind this, @createInvitationCode, (err)->
              unless err.code is 11000
                return err.message ? 'An error occured! Please try again later.'
              return 'Invitation code already exists. Please try a different one or leave empty to generate'
        submitButtonLabel : 'Create'
        fields            :
          invitationCode  :
            label         : "Invitation code"
            itemClass     : KDInputView
            name          : "code"
            placeholder   : "Enter a creative invitation code!"
            defaultValue  : suggestedCode
            nextElement   :
              Suggest     :
                itemClass : KDButtonView
                cssClass  : 'clean-gray suggest-button'
                callback  : =>
                  KD.remote.api.JInvitation.suggestCode (err, suggestedCode)=>
                    return @showErrorMessage err  if err
                    form = @createInvitationCode.modalTabs.forms.invite
                    form.inputs.invitationCode.setValue suggestedCode
          maxUses         :
            label         : "Maximum uses"
            itemClass     : KDInputView
            name          : "maxUses"
            placeholder   : "How many people can redeem this code?"

  showInviteByEmailModal:->
    defaultMessage =
      """
      Hi there,

      #INVITER# has invited you to the group #{@getData().title}.

      This link will allow you to join the group: #URL#

      If you reply to this email, it will go to #INVITER#.

      Enjoy! :)
      """

    @inviteByEmail = @showModalForm
      title              : 'Invite by Email'
      cssClass           : 'invite-by-email'
      callback           : ({emails, message, saveMessage})=>
        @getData().inviteByEmails emails, message, (err)=>
          @modalCallback @inviteByEmail, noop, err
          if saveMessage
            @getData().saveInvitationMessage message
            @getData().invitationMessage = message
      fields             :
        emails           :
          label          : 'Emails'
          type           : 'textarea'
          cssClass       : 'emails-input'
          placeholder    : 'Enter each email address on a new line...'
          validate       :
            rules        :
              required   : yes
            messages     :
              required   : 'At least one email address required!'
        message          :
          label          : 'Message'
          type           : 'textarea'
          cssClass       : 'message-input'
          defaultValue   : @getData().invitationMessage or defaultMessage
          validate       :
            rules        :
              required   : yes
              regExp     : /(#URL#)+/
            messages     :
              required   : 'Message is required!'
              regExp     : 'Message must contain #URL# for invitation link!'
        saveMessage      :
          type           : 'checkbox'
          cssClass       : 'save-message'
          defaultValue   : no
          nextElement    :
            saveMsgLabel :
              itemClass  : KDLabelView
              title      : 'Remember this message'
              click      : (event)=>
                @inviteByEmail.modalTabs.forms.invite.fields.saveMessage.subViews.first.subViews.first.getDomElement().click()
        report           :
          itemClass      : KDScrollView
          cssClass       : 'report'

    form = @inviteByEmail.modalTabs.forms.invite

    form.fields.report.hide()

  showBulkApproveModal:->
    subject = if @policy.approvalEnabled then 'Membership' else 'Invitation'
    @bulkApprove = @showModalForm
      title            : "Bulk Approve #{subject} Requests"
      callback         : ({count})=>
        @getData().sendSomeInvitations count,
          @modalCallback.bind this, @bulkApprove, noop
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

  modalCallback:(modal, errCallback, err)->
    form = modal.modalTabs.forms.invite
    form.buttons.Send.hideLoader()
    @tabView.getActivePane().subViews.first.refresh()
    if err
      unless Array.isArray err or form.fields.report
        return @showErrorMessage err, errCallback
      else
        form.fields.report.show()
        scrollView = form.fields.report.subViews.first.subViews.first
        err.forEach (errLine)->
          errLine = if errLine?.message then errLine.message else errLine
          scrollView.setPartial "#{errLine}<br/>"
        return scrollView.scrollTo top:scrollView.getScrollHeight()

    new KDNotificationView title:'Invitation sent!'
    modal.destroy()

  showErrorMessage:(err, errCallback)->
    warn err
    new KDNotificationView
      title    : msgCallback?(err) ? err.message ? 'An error occured! Please try again later.'
      duration : 2000
