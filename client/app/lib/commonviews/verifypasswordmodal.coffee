kd = require 'kd'
KDModalViewWithForms = kd.ModalViewWithForms
KDNotificationView = kd.NotificationView
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
ContentModal = require 'app/components/contentModal'

module.exports = class VerifyPasswordModal extends ContentModal

  constructor: (buttonTitle = 'Submit', partial = '', callback) ->

    cssClass = 'content-modal verify-password'
    cssClass = "#{cssClass} with-partial"  if partial


    options =
      title                       : 'Please verify your password'
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
                placeholder       : 'Enter your password'
                type              : 'password'
                validate          :
                  rules           :
                    required      : yes
                  messages        :
                    required      : 'Current Password required!'


    super options

    $('.transferbutton').on 'click', =>
      kd.singletons.router.handleRoute '/Home/my-team#actions'
      @destroy()

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
