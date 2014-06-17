class VerifyPasswordModal extends KDModalViewWithForms

  constructor:(buttonTitle = "Submit", callback) ->

    options =
      title                       : "Please verify your current password "
      overlay                     : yes
      overlayClick                : no
      width                       : 605
      height                      : "auto"
      cancel                      : =>
        callback null
        @destroy()
      tabs                        :
        navigable                 : yes
        forms                     :
          verifyPasswordForm      :
            callback              : =>
              callback @modalTabs.forms.verifyPasswordForm.inputs.password.getValue()
              @destroy()
            buttons               :
              Submit              :
                title             : buttonTitle
                cssClass          : "modal-clean-green"
                type              : "submit"
              Forgot              :
                title             : "Forgot Password?"
                callback          : =>
                  {entryPoint} = KD.config
                  KD.singleton("router").handleRoute "/Recover", {entryPoint}
                  @destroy()

            fields                :
              password            :
                name              : "password"
                placeholder       : "current password"
                type              : "password"
                validate          :
                  rules           :
                    required      : yes
                  messages        :
                    required      : "Current Password required!"

    super options