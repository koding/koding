kd = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms


module.exports = class VerifyPINModal extends KDModalViewWithForms

  constructor: (buttonTitle = 'Submit', callback) ->

    options =
      title                       : "Please provide the code that we've emailed"
      overlay                     : yes
      overlayClick                : no
      width                       : 605
      height                      : 'auto'
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
                cssClass          : 'solid green medium'
                type              : 'submit'
            fields                :
              pin                 :
                name              : 'pin'
                placeholder       : 'Code'
                testPath          : 'account-email-pin'
                validate          :
                  rules           :
                    required      : yes
                  messages        :
                    required      : 'Code required!'

    super options
