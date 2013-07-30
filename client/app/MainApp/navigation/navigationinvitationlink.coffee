class NavigationInviteLink extends KDCustomHTMLView

  constructor:(options = {}, data)->

    options.tagName  = "a"
    options.cssClass = "title"

    super options, data

    @hide()

    @count = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon #{__utils.slugify @getData().title}"
      pistachio : "{{#(quota)-#(usage)}}"

    @utils.wait 7500, =>
      KD.whoami().fetchLimit? 'invite', (err, limit)=>
        if limit?
          limit.on 'update', => @count.render()
          @count.setData limit
          @count.render()
          @show()

  sendInvite:(formData, modal)->

    KD.remote.api.JInvitation.create
      emails        : [formData.recipient]
      group         : "koding"
      customMessage :
        # subject     : formData.subject
        body        : formData.body
    , (err)=>
      modal.modalTabs.forms["Invite Friends"].buttons.Send.hideLoader()
      if err
        message = 'This e-mail is already invited!' if err.code is 11000
        new KDNotificationView
          title: message or err.message or 'Sorry, something bad happened.'
          content: 'Please try again later!' unless message
      else
        new KDNotificationView title: 'Success!'
        modal.destroy()
        KD.track "Members", "InvitationSentToFriend", formData.recipient

  viewAppended: JView::viewAppended

  pistachio:-> "{{> @count}}#{@getData().title}"

  # take this somewhere else
  # was a beta quick solution
  click:(event)->
    event.stopPropagation()
    event.preventDefault()
    limit = @count.getData()
    if !limit? or limit.getAt('quota') - limit.getAt('usage') <= 0
      new KDNotificationView
        title   : 'You are temporarily out of invitations.'
        content : 'Please try again later.'
    else
      return if @modal
      @modal = modal = new KDModalViewWithForms
        title                   : "<span class='invite-icon'></span>Invite Friends to Koding"
        content                 : ""
        width                   : 500
        height                  : "auto"
        cssClass                : "invitation-modal"
        tabs                    :
          forms                 :
            "Invite Friends"    :
              callback          : (formData)=>
                @sendInvite formData, modal
              fields            :
                recipient       :
                  label         : "Send To:"
                  type          : "text"
                  name          : "recipient"
                  placeholder   : "Enter your friend's email address..."
                  validate      :
                    rules       :
                      required  : yes
                      email     : yes
                    messages    :
                      required  : "An email address is required!"
                      email     : "That does not not seem to be a valid email address!"
                # Subject         :
                #   label         : "Subject:"
                #   type          : "text"
                #   name          : "subject"
                #   placeholder   : "Come try Koding, a new way for developers to work..."
                #   defaultValue  : "Come try Koding, a new way for developers to work..."
                #   # attributes    :
                #   #   readonly    : yes
                Message         :
                  label         : "Message:"
                  type          : "textarea"
                  name          : "body"
                  placeholder   : "Hi! You're invited to try out Koding, a new way for developers to work."
                  defaultValue  : "Hi! You're invited to try out Koding, a new way for developers to work."
                  # attributes    :
                  #   readonly    : yes
              buttons           :
                Send            :
                  style         : "modal-clean-gray"
                  type          : 'submit'
                  loader        :
                    color       : "#444444"
                    diameter    : 12
                cancel          :
                  style         : "modal-cancel"
                  callback      : ->
                    modal.destroy()

    modal.on "KDModalViewDestroyed", => @modal = null

    inviteForm = modal.modalTabs.forms["Invite Friends"]
    inviteForm.on "FormValidationFailed", => inviteForm.buttons["Send"].hideLoader()

    modalHint = new KDView
      cssClass  : "modal-hint"
      partial   : "<p>Your friend will receive an Email from Koding that
                   includes a unique invite link so they can register for
                   the Koding Public Beta.</p>
                   <p><cite>* We take privacy seriously, we will not share any personal information.</cite></p>"

    modal.modalTabs.addSubView modalHint, null, yes

    inviteHint = new KDView
      cssClass  : "invite-hint fl"
      pistachio : "{{#(quota)-#(usage)}} Invites remaining"
    , @count.getData()

    modal.modalTabs.panes[0].form.buttonField.addSubView inviteHint, null, yes

    return no

