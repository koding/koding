$ = require 'jquery'
uploadLogs = require '../util/uploadLogs'
kd = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView = kd.NotificationView

module.exports = class HelpSupportModal extends KDModalViewWithForms

  constructor: (options = {}, data)->

    options                 = kd.utils.extend options,
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

      # if @_logUrl? ~ We are uploading logs but not including it 
      #                into the support ticket ~ GG #89350576
      #   message += "\n\n --- LOGS: #{@_logUrl} --- \n"

      request = $.ajax "#{global.location.origin}/-/support/new",
        type        : "POST"
        contentType : "application/json"
        data        : JSON.stringify { subject, message }
        timeout     : 4000
        dataType    : "json"

      request.done  =>
        new KDNotificationView title: "Thanks! We will send you an email within 24 hours."
        submit.hideLoader()
        submit.setCallback @bound 'destroy'
        submit.setTitle "CLOSE"

      request.error =>
        new KDNotificationView title: "Sorry, could not process your request, please try again."
        submit.hideLoader()
        @ticketRequested = no

    uploadLogs (err, logUrl)=>
      @_logUrl = logUrl  if not err and logUrl?


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

        <a href="http://learn.koding.com/guides/change-theme/" target="_blank">
          Changing IDE and Terminal themes</a><br/>

        <div class="koding-university">
          Head over to <a href="http://learn.koding.com/faq/" target="_blank">Koding University</a> for more...
        </div>

        <div class="message-footer">
          To view the onboarding process again,<br />press <span class="f1-button">F1</span>.
        </div>
      </div>
    """

