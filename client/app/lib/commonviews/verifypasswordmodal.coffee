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
                style             : 'solid medium cancel'
                title             : 'Forgot Password?'
                callback          : =>
                  account = whoami()
                  account.fetchEmail (err, email) =>
                    return @showError err  if err
                    @doRecover email
                    @destroy()
              Submit              :
                title             : buttonTitle
                style             : 'solid green medium'
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
