kd = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView = kd.NotificationView
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
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
                  account = whoami()
                  account.fetchEmail (err, email) =>
                    return @showError err  if err
                    @doRecover email
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

  doRecover:(email)->
    $.ajax
      url         : '/Recover'
      data        : { email, _csrf : Cookies.get '_csrf' }
      type        : 'POST'
      error       : (xhr) =>
        {responseText} = xhr
        new KDNotificationView title : responseText
      success     : =>
        new KDNotificationView
          title     : "Check your email"
          content   : "We've sent you a password recovery code."
          duration  : 4500
