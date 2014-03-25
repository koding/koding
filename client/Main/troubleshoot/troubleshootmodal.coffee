class TroubleshootModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->
    troubleshoot = KD.singleton("troubleshoot")

    options =
      title                 : "Checking Koding Status"
      overlay               : yes
      cssClass              : "troubleshoot-modal"
      cancelable            : no
      tabs                  :
        forms               :
          Troubleshoot      :
            callback        : =>
              {feedback} = @modalTabs.forms.Troubleshoot.customData
              troubleshoot.sendFeedback feedback, (err) =>
                return warn "an error occured while sending feedback"  if err
                @showFeedbackSentModal()
              @destroy()
            buttons         :
              sendFeedback  :
                title       : "Send Feedback"
                style       : "modal-clean-green"
                type        : "submit"
                loader      :
                  color     : "#444444"
                  diameter  : 12
                callback    : -> @hideLoader()
              recover       :
                title       : "Recover"
                style       : "modal-clean-red"
                callback    : -> troubleshoot.recover()
              close         :
                title       : "Close"
                style       : "modal-cancel"
                callback    : => @destroy()
            fields          :
              check         :
                label       : "System Status"
                itemClass   : TroubleshootStatusView
              result        :
                itemClass   : KDCustomHTMLView
                cssClass    : "troubleshoot-result"
                partial     : "Troubleshooting Completed"
              errors        :
                # label       : "Errors"
                itemClass   : TroubleshootResultView
                # cssClass    : "hidden"
              feedback      :
                label       : "Feedback"
                name        : "feedback"
                placeholder : "Please tell us about the problems you were having and describe the situation"
                type        : "textarea"
                autogrow    : yes

    super options, data

    @overlay.off "click"
    @hideFeedback()
    @modalTabs.forms.Troubleshoot.buttons.close.hide()
    @modalTabs.forms.Troubleshoot.fields.result.hide()

    troubleshoot.on "recoveryCompleted", =>
      @hideFeedback()  if troubleshoot.isSystemOK()


    troubleshoot.once "troubleshootCompleted", =>
      # show feedback form if there are any errors apart from connection down
      @modalTabs.forms.Troubleshoot.buttons.close.show()
      if troubleshoot.isSystemOK()
        return @modalTabs.forms.Troubleshoot.fields.result.show()
      {connection} = troubleshoot.items
      @showFeedback()  if connection?.status isnt "fail"


    KD.troubleshoot()

  hideFeedback: ->
    @modalTabs.forms.Troubleshoot.fields.feedback.hide()
    @modalTabs.forms.Troubleshoot.buttons.sendFeedback.hide()
    @modalTabs.forms.Troubleshoot.buttons.recover.hide()

  showFeedback: ->
    @modalTabs.forms.Troubleshoot.fields.feedback.show()
    @modalTabs.forms.Troubleshoot.buttons.sendFeedback.show()
    if KD.singleton("troubleshoot").canBeRecovered()
      @modalTabs.forms.Troubleshoot.buttons.recover.show()

  destroy: ->
    KD.singleton("troubleshoot").off "recoveryCompleted"
    {items} = KD.singleton("troubleshoot")
    for own key, item of items
      item.off "recoveryStarted"
      item.off "recoveryCompleted"
    super

  showFeedbackSentModal: ->
    modal = new KDModalView
      title        : "Thank you for your support"
      overlay      : yes
      content      : "We have received your feedback."
      buttons      :
        Close      :
          style    : "modal-cancel"
          callback : -> modal.destroy()
