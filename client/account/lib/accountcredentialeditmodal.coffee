kd                  = require 'kd'
KDModalView         = kd.ModalView
KDView              = kd.CustomHTMLView
KDNotificationView  = kd.NotificationView
showError           = require 'app/util/showError'
contentModal = require 'app/components/contentModal'

module.exports = class AccountCredentialEditModal extends contentModal


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'content-modal with-form', options.cssClass
    options.title   or= 'Edit Credential'

    super options, data

    { ui }                    = kd.singletons.computeController
    { credential, provider }  = options

    formOptions       =
      provider        : provider
      defaultValues   : data.meta
      defaultTitle    : data.title
      requiredFields  : credential.fields
      callback        : (title, data) =>

        credential.update {
          provider, title, meta: data
        }, (err, credential) =>
          @form.buttons.Save.hideLoader()

          unless showError err
            @form.emit 'CredentialUpdated', credential


    # @main.addSubView @wrapper = new KDView { cssClass : '', tagName: 'main' }

    @main.addSubView @form = ui.generateAddCredentialFormFor formOptions

    @form.on 'Cancel', @bound 'cancel'

    @form.on 'CredentialUpdated', =>
      new KDNotificationView { title : 'Credential was updated.', type: 'mini' }
      @cancel()
