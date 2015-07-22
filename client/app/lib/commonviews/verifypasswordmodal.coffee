kd = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms
globals = require 'globals'


module.exports = class VerifyPasswordModal extends KDModalViewWithForms

  constructor:(buttonTitle = "Submit", callback) ->

    options =
      title                       : "Please verify your current password "
      overlay                     : yes
      overlayClick                : no
      width                       : 605
      height                      : "auto"
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
                style             : "solid green medium"
                type              : "submit"
              Forgot              :
                style             : "solid light-gray medium"
                title             : "Forgot Password?"
                callback          : =>
                  @destroy()
                  {entryPoint} = globals.config
                  kd.singleton("router").handleRoute "/Recover", {entryPoint}

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
