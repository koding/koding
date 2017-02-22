kd = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView = kd.NotificationView
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
ContentModal = require 'app/components/contentModal'

module.exports = class VerifyPasswordModal extends ContentModal

  constructor: (buttonTitle = 'Submit', partial = '', callback) ->

    cssClass = 'content-modal'
    cssClass = 'content-modal with-partial'  if partial


    options =
      title                       : 'Please verify your current password'
      cssClass                    : cssClass
      overlay                     : yes
      overlayClick                : no
      width                       : 605
      tabs                        :
        navigable                 : yes
        forms                     :
          verifyPasswordForm      :
            callback              : =>
              callback @modalTabs.forms.verifyPasswordForm.inputs.password.getValue()
              @destroy()
            buttons               :
              Forgot              :
                style             : 'GenericButton cancel'
                title             : 'Forgot Password?'
                callback          : =>
                  account = whoami()
                  account.fetchEmail (err, email) =>
                    return @showError err  if err
                    @doRecover email
                    @destroy()
              Submit              :
                title             : buttonTitle
                style             : 'GenericButton'
                type              : 'submit'

            fields                :
              planDetails     :
                type          : 'hidden'
                cssClass      : 'hidden'  unless partial
                nextElement   :
                  planDetails :
                    cssClass  : 'content'
                    itemClass : kd.View
                    partial   : partial
              password            :
                name              : 'password'
                cssClass          : 'line-with'
                label             : 'Current Password'
                placeholder       : 'Enter your current password'
                type              : 'password'
                validate          :
                  rules           :
                    required      : yes
                  messages        :
                    required      : 'Current Password required!'


    super options

  doRecover: (email) ->

    { notificationViewController: { addNotification } } = kd.singletons


    $.ajax
      url         : '/Recover'
      data        : { email, _csrf : Cookies.get '_csrf' }
      type        : 'POST'
      error       : (xhr) ->
        { responseText } = xhr
        addNotification
          type: 'caution'
          duration: 5000
          content: responseText

      success     : ->
        addNotification
          type: 'success'
          content: "Check your email... We've sent you a password recovery code."
          duration: 5000
