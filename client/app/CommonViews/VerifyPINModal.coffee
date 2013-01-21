
class VerifyPINModal extends KDModalViewWithForms

  constructor:(buttonTitle = "Submit", callback) ->

    options =
      title                       : "Please provide the PIN that we've emailed you"
      overlay                     : yes
      width                       : 400
      height                      : "auto"
      tabs                        :
        navigable                 : yes
        forms                     :
          form                    :
            callback              : =>
              callback @modalTabs.forms.form.inputs.pin.getValue()
              @destroy()
            buttons               :
              Submit              :
                title             : buttonTitle
                cssClass          : "modal-clean-gray"
                type              : "submit"
            fields                :
              pin                 :
                label             : "PIN:"
                name              : "pin"
                placeholder       : "PIN"
                validate          :
                  rules           :
                    required      : yes
                  messages        :
                    required      : "PIN required!"

    super options