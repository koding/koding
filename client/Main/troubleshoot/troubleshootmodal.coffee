class TroubleshootModal extends KDModalViewWithForms

  constructor: (options = {}, data) ->
    troubleshoot = KD.singleton("troubleshoot")

    options =
        title                 : "Checking Koding Status"
        overlay               : yes
        cssClass              : "troubleshoot-modal"
        tabs                  :
          forms               :
            Troubleshoot      :
              callback        : =>
                {feedback} = @modalTabs.forms.Troubleshoot.customData
                KD.logToExternal "troubleshoot feedback", {failure:troubleshoot.getFailureFeedback(), feedback}
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
                  itemClass   : TroubleshootResultView
                  partial     : "Successfully Completed"
                errors        :
                  # label       : "Errors"
                  itemClass   : TroubleshootErrorView
                  # cssClass    : "hidden"
                feedback      :
                  label       : "Feedback"
                  itemClass   : KDInputView
                  name        : "feedback"
                  placeholder : "Define the situation"

    super options, data
    @hideFeedback()
    @modalTabs.forms.Troubleshoot.fields.result.hide()
    troubleshoot.once "troubleshootCompleted", =>
      # show feedback form if there are any errors apart from connection down

      if troubleshoot.isSystemOK()
        return @modalTabs.forms.Troubleshoot.fields.result.show()
      @showFeedback()  unless troubleshoot.isConnectionFailed()


    KD.troubleshoot()

  hideFeedback: ->
    @modalTabs.forms.Troubleshoot.fields.feedback.hide()
    @modalTabs.forms.Troubleshoot.buttons.sendFeedback.hide()

  showFeedback: ->
    @modalTabs.forms.Troubleshoot.fields.feedback.show()
    @modalTabs.forms.Troubleshoot.buttons.sendFeedback.show()

class TroubleshootResultView extends KDCustomHTMLView

  constructor: (options, data) ->
    options.cssClass = "troubleshoot-result"
    super options, data