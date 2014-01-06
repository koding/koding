
class VerifyPINModal extends KDModalViewWithForms

  constructor:(buttonTitle = "Submit", callback) ->

    options =
      title                       : "Please provide the PIN that we've emailed you"
      overlay                     : yes
      width                       : 605
      height                      : "auto"
      tabs                        :
        navigable                 : yes
        forms                     :
          verifyPINForm           :
            callback              : =>
              callback @modalTabs.forms.verifyPINForm.inputs.pin.getValue()
              @destroy()
            buttons               :
              Submit              :
                title             : buttonTitle
                cssClass          : "modal-clean-green"
                type              : "submit"
            fields                :
              pin                 :
                name              : "pin"
                placeholder       : "PIN"
                testPath          : "account-email-pin"
                validate          :
                  rules           :
                    required      : yes
                  messages        :
                    required      : "PIN required!"

    super options