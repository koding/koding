kd = require 'kd'
ContentModal = require 'app/components/contentModal'

module.exports = class VerifyPINModal extends ContentModal

  constructor: (buttonTitle = 'Submit', callback) ->

    options =
      cssClass                    : 'content-modal'
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
                cssClass          : 'GenericButton'
                type              : 'submit'
            fields                :
              pin                 :
                name              : 'pin'
                placeholder       : 'Enter pin code'
                label             : 'Pin code'
                testPath          : 'account-email-pin'
                validate          :
                  rules           :
                    required      : yes
                  messages        :
                    required      : 'Code required!'

    super options
