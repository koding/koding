class HelpSupportModal extends KDModalViewWithForms

  constructor: (options = {}, data)->

    options                 = KD.utils.extend options,
      title                 : "Koding Support"
      subtitle              : "Let's get you some help shall we?"
      cssClass              : "help-support-modal"
      overlay               : yes
      overlayClick          : yes
      width                 : 668
      content               : HelpSupportModal.getTopics()
      tabs                  :
        callback            : (form)=> @emit "NewTicketRequested", form
        forms               :
          Main              :
            buttons         :
              submit        :
                title       : "SEND"
                style       : "solid green medium"
                type        : "submit"
                loader      : yes
            fields          :
              subject       :
                label       : "Subject"
                type        : "text"
                placeholder : "Subject about your problem..."
                validate    : rules: required: yes
              message       :
                label       : "Message"
                type        : "textarea"
                placeholder : "
                  Detailed message about your problem.
                  If it is a techincal issue, please also
                  provide what caused the issue and a
                  link to a screenshot.
                "
                validate    : rules: required: yes

    super options, data

    @on "NewTicketRequested", (form)=>

      return if @ticketRequested
      @ticketRequested = yes

      {submit} = @modalTabs.forms.Main.buttons
      {subject, message} = form

      request = $.ajax "#{window.location.origin}/-/support/new",
        type        : "POST"
        contentType : "application/json"
        data        : JSON.stringify { subject, message }
        timeout     : 4000
        dataType    : "json"

      request.done  =>
        new KDNotificationView title: "Your message has been sent!"
        submit.hideLoader()
        submit.setCallback @bound 'destroy'
        submit.setTitle "CLOSE"

      request.error =>
        new KDNotificationView title: "Failed to create ticket, please try again"
        submit.hideLoader()
        @ticketRequested = no


  @getTopics = ->
    """
      <div class="container">
        <div class="topics-header">Some popular help topics</div>

        <a href="http://learn.koding.com/faq/#what-is-koding" target="_blank">
          What is Koding?</a><br/>

        <a href="http://learn.koding.com/faq/#what-is-my-sudo-password" target="_blank">
          What is my sudo password?</a><br/>

        <a href="http://learn.koding.com/guides/ssh-into-your-vm/" target="_blank">
          How do I ssh into my Koding VM?</a><br/>

        <a href="http://learn.koding.com/faq/#vm-poweroff" target="_blank">
          How do I turn off my VM?</a><br/>

        <a href="http://learn.koding.com/migrate" target="_blank">
          How do I migrate my old VM(s)?</a><br/>

        <div class="message-footer">
          Head over to <a href="http://learn.koding.com/faq/" target="_blank">Koding University</a> for more...
        </div>
      </div>
    """