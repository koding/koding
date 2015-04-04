kd = require 'kd'
KDButtonView = kd.ButtonView
KDInputView = kd.InputView
KDLabelView = kd.LabelView
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView = kd.NotificationView
KDScrollView = kd.ScrollView
KDTabHandleContainer = kd.TabHandleContainer
KDView = kd.View
GroupTabHandleView = require './grouptabhandleview'
GroupsInvitationTabView = require './groupsinvitationtabview'
remote = require('app/remote').getInstance()
whoami = require 'app/util/whoami'
doesEmailValid = require 'app/util/doesEmailValid'
showError = require 'app/util/showError'
Encoder = require 'htmlencode'


module.exports = class GroupsInvitationView extends KDView

  constructor:(options={}, data)->
    options.cssClass = 'member-related'
    super options, data

    @getData().fetchMembershipPolicy (err, @policy)=>
      if err?
        warn "Failed to fetch membershippolicy:", err
        @policy = {}

      @addSubView tabHandleContainer = new KDTabHandleContainer
      @addSubView @tabView = new GroupsInvitationTabView {
        delegate           : this
        tabHandleClass     : GroupTabHandleView
        tabHandleContainer
      }, data

      unless @policy?.communications?.inviteApprovedMessage
        @saveInviteMessage 'inviteApprovedMessage', @getDefaultInvitationMessage()

    @on 'SearchInputChanged', (value)=>
      @tabView.getActivePane().mainView.emit 'SearchInputChanged', value

  showModalForm:(options)->
    modal = new KDModalViewWithForms
      cssClass               : options.cssClass
      title                  : options.title
      content                : options.content
      overlay                : yes
      width                  : options.width
      height                 : options.height
      tabs                   :
        forms                :
          invite             :
            callback         : options.callback
            buttons          :
              Send           :
                itemClass    : KDButtonView
                testPath     : "groups-dashboard-invite-button"
                title        : options.submitButtonLabel or 'Send'
                style        : "solid green medium"
                type         : 'submit'
                loader       :
                  color      : '#444444'
              Cancel         :
                style        : "solid red medium"
                callback     : -> modal.destroy()
            fields           : options.fields

    form = modal.modalTabs.forms.invite
    form.on 'FormValidationFailed', => form.buttons.Send.hideLoader()

    return modal

  showCreateInvitationCodeModal:->
    remote.api.JInvitation.suggestCode (err, suggestedCode)=>
      return @showErrorMessage err  if err
      @createInvitationCode = @showModalForm
        title             : 'Create an Invitation Code'
        cssClass          : 'create-invitation-code'
        callback          : (formData)=>
          remote.api.JInvitation.createMultiuse formData,
            @modalCallback.bind this, @createInvitationCode, (err)->
              unless err.code is 11000
                return err.message ? 'An error occurred! Please try again later.'
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
                cssClass  : 'solid suggest-button'
                callback  : =>
                  remote.api.JInvitation.suggestCode (err, suggestedCode)=>
                    return @showErrorMessage err  if err
                    form = @createInvitationCode.modalTabs.forms.invite
                    form.inputs.invitationCode.setValue suggestedCode
          maxUses         :
            label         : "Maximum uses"
            itemClass     : KDInputView
            name          : "maxUses"
            placeholder   : "How many times can this code be redeemed?"
            validate      :
              rules       :
                required  : yes
                regExp    : /\d+/i
              messages    :
                required  : 'Max usage is required'
                regExp    : 'numbers only please'
          memo            :
            label         : "Memo"
            itemClass     : KDInputView
            name          : "memo"
            placeholder   : "(optional)"

  getDefaultInvitationMessage:->
    fullName = "#{whoami().profile.firstName} #{whoami().profile.lastName}"
    """
    Hi there,

    #{fullName} has invited you to the group #{@getData().title}.

    This link will allow you to join the group: #URL#

    If you reply to this email, it will go to #{fullName}.

    Enjoy! :)
    """

  showEditInviteMessageModal:->
    @editInviteMessage = @showModalForm
      title              : 'Edit Invitation Message'
      cssClass           : 'edit-invitation-message'
      width              : '540'
      submitButtonLabel  : 'Save'
      callback           : ({message})=>
        @saveInviteMessage 'inviteApprovedMessage', message, (err)=>
          @editInviteMessage.modalTabs.forms.invite.buttons.Send.hideLoader()
          unless err
            new KDNotificationView title:'Message saved'
            @editInviteMessage.destroy()
          else
            @showErrorMessage err
      fields             :
        message          :
          label          : 'Message'
          type           : 'textarea'
          cssClass       : 'message-input'
          defaultValue   : Encoder.htmlDecode @policy?.communications?.inviteApprovedMessage or @getDefaultInvitationMessage()
          validate       :
            rules        :
              required   : yes
              regExp     : /(#URL#)+/
            messages     :
              required   : 'Message is required!'
              regExp     : 'Message must contain #URL# for invitation link!'

  showInviteByEmailModal:->
    @inviteByEmail = @showModalForm
      title              : 'Invite by Email'
      cssClass           : 'invite-by-email'
      callback           : ({emails, message, saveMessage})=>
        whoami().fetchFromUser "email", (err, userEmail)=>
          emails = emails.trim()
          invalidEmails = []
          emailList = emails.split(/\n/).map (email)-> email.trim()
          emailList = emailList.filter (email) ->
            isValid = doesEmailValid email
            invalidEmails.push email  unless isValid
            isValid

          if invalidEmails.length
            @inviteByEmail.modalTabs.forms.invite.buttons.Send.hideLoader()
            return showError "Your invitations includes some invalid emails: #{invalidEmails}"

          if userEmail in emailList
            @inviteByEmail.modalTabs.forms.invite.buttons.Send.hideLoader()
            return new KDNotificationView
              title: "You cannot invite yourself!"

          @getData().inviteByEmails emails, {message}, (err)=>
            @modalCallback @inviteByEmail, kd.noop, err
            @saveInviteMessage 'invitationMessage', message  if saveMessage
      fields             :
        emails           :
          label          : 'Emails'
          type           : 'textarea'
          cssClass       : 'emails-input'
          testPath       : "groups-dashboard-invite-list"
          placeholder    : 'Enter each email address on a new line...'
          validate       :
            notifications: yes
            rules        :
              required   : yes
            messages     :
              required   : 'At least one email address required!'
        message          :
          label          : 'Message'
          type           : 'textarea'
          cssClass       : 'message-input'
          defaultValue   : Encoder.htmlDecode @policy?.communications?.invitationMessage or @getDefaultInvitationMessage()
          validate       :
            notifications: yes
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

    @inviteByEmail.modalTabs.forms.invite.fields.report.hide()

  showBulkApproveModal:->
    subject = if @policy.approvalEnabled then 'Membership' else 'Invitation'
    @bulkApprove = @showModalForm
      title            : "Bulk Approve #{subject} Requests"
      cssClass         : 'bulk-approve'
      width            : '540'
      callback         : ({count, bcc})=>
        @getData().sendSomeInvitations count, {bcc}, (err, emails)=>
          kd.log 'successfully approved/invited: ', emails
          @modalCallback @bulkApprove, kd.noop, err
      submitButtonLabel: if @policy.approvalEnabled then 'Approve' else 'Invite'
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
        bcc            :
          label        : 'BCC'
          type         : 'text'
          placeholder  : '(optional)'
        report           :
          itemClass      : KDScrollView
          cssClass       : 'report'

    @bulkApprove.modalTabs.forms.invite.fields.report.hide()

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

    new KDNotificationView title:'Success!'
    modal.destroy()

  saveInviteMessage:(messageType, message, callback=kd.noop)->
    callback {message:"not implemented"}

  showErrorMessage:(err, errCallback)->
    kd.warn err
    new KDNotificationView
      title    : msgCallback?(err) ? err.message ? 'An error occurred! Please try again later.'
      duration : 2000


