kd = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView = kd.NotificationView
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
contentModal = require 'app/components/contentModal'

module.exports = class VerifyPasswordModal extends contentModal

  constructor: (buttonTitle = 'Submit', partial = '', callback) ->

    cssClass = 'content-modal'
    cssClass = 'content-modal with-partial'  if partial

    console.log {cssClass}

    options =
      title                       : 'Please Verify Your Current Password'
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
              Submit              :
                title             : buttonTitle
                style             : 'solid green medium'
                type              : 'submit'
              Forgot              :
                style             : 'solid medium'
                title             : 'Forgot Password?'
                callback          : =>
                  account = whoami()
                  account.fetchEmail (err, email) =>
                    return @showError err  if err
                    @doRecover email
                    @destroy()

            fields                :
              planDetails     :
                type          : 'hidden'
                nextElement   :
                  planDetails :
                    cssClass  : 'content'
                    itemClass : kd.View
                    partial   : partial
              password            :
                name              : 'password'
                placeholder       : 'current password'
                type              : 'password'
                validate          :
                  rules           :
                    required      : yes
                  messages        :
                    required      : 'Current Password required!'


    super options

  doRecover: (email) ->
    $.ajax
      url         : '/Recover'
      data        : { email, _csrf : Cookies.get '_csrf' }
      type        : 'POST'
      error       : (xhr) ->
        { responseText } = xhr
        new KDNotificationView { title : responseText }
      success     : ->
        new KDNotificationView
          title     : 'Check your email'
          content   : "We've sent you a password recovery code."
          duration  : 4500
