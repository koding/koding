class NavigationInviteLink extends KDCustomHTMLView

  constructor:(options = {}, data)->
    options.tagName  = "a"
    options.cssClass = "title"

    super options, data

    @icon = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon #{utils.slugify @getData().title}"

    @hide()  if KD.config.entryPoint?.slug

  sendInvite:(formData, modal)->
    KD.remote.api.JInvitation.inviteFriend formData, (err)=>
      modal.modalTabs.forms["Invite Friends"].buttons.Send.hideLoader()
      if err
        message = 'This e-mail is already invited!'  if err.code is 11000
        new KDNotificationView
          title   : message or err.message or 'Sorry, something bad happened.'
          content : 'Please try again later!'  unless message
      else
        new KDNotificationView title: 'Success!'
        modal.destroy()
        KD.mixpanel "Invite friend, success"

  viewAppended: JView::viewAppended

  pistachio:-> "{{> @icon}} #{@getData().title}"

  # take this somewhere else
  # was a beta quick solution
  click:(event)->
    event.stopPropagation()
    event.preventDefault()

    modal = new KDModalViewWithForms
      title                   : "<span class='invite-icon'></span>Invite Friends to Koding"
      width                   : 500
      height                  : "auto"
      cssClass                : "invitation-modal"
      tabs                    :
        forms                 :
          "Invite Friends"    :
            callback          : (formData)=> @sendInvite formData, modal
            fields            :
              email           :
                label         : "Send To:"
                placeholder   : "Enter your friend's email address..."
                validate      :
                  rules       :
                    required  : yes
                    email     : yes
                  messages    :
                    required  : "An email address is required!"
                    email     : "That does not not seem to be a valid email address!"
              customMessage   :
                label         : "Message:"
                type          : "textarea"
                placeholder   : "Hi! You're invited to try out Koding, a new way for developers to work."
                defaultValue  : "Hi! You're invited to try out Koding, a new way for developers to work."
            buttons           :
              Send            :
                style         : "modal-clean-gray"
                type          : 'submit'
                loader        :
                  color       : "#444444"
                  diameter    : 12
              cancel          :
                style         : "modal-cancel"
                callback      : -> modal.destroy()

    inviteForm = modal.modalTabs.forms["Invite Friends"]
    inviteForm.on "FormValidationFailed", => inviteForm.buttons["Send"].hideLoader()

    modalHint = new KDView
      cssClass  : "modal-hint"
      partial   : "<p>Your friend will receive an invitation email from Koding.</p>
                   <p><cite>* We take privacy seriously, we will not share any personal information.</cite></p>"

    modal.modalTabs.addSubView modalHint, null, yes

    inviteHint = new KDView
      cssClass  : "invite-hint fl"
      pistachio : "{{#(quota)-#(usage)}} Invites remaining"
    , @count.getData()

    modal.modalTabs.panes[0].form.buttonField.addSubView inviteHint, null, yes

    return no

