kd                  = require 'kd'
KDView              = kd.CustomHTMLView
KDNotificationView  = kd.NotificationView
showError           = require 'app/util/showError'
ContentModal = require 'app/components/contentModal'
Encoder = require 'htmlencode'

module.exports = class AccountCredentialEditModal extends ContentModal


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'content-modal with-form', options.cssClass
    options.title or= 'Edit Credential'
    options.width = 500
    options.overlay = yes

    super options, data

    { ui }                    = kd.singletons.computeController
    { credential, provider }  = options

    { meta, title } = data

    title = Encoder.htmlDecode title

    formOptions       =
      provider        : provider
      defaultValues   : meta
      defaultTitle    : title
      requiredFields  : credential.fields
      callback        : (title, data) =>

        credential.update {
          provider, title, meta: data
        }, (err, credential) =>
          @form.buttonField.buttons.Save.hideLoader()

          unless showError err
            @form.emit 'CredentialUpdated', credential


    # @main.addSubView @wrapper = new KDView { cssClass : '', tagName: 'main' }

    @main.addSubView @form = ui.generateAddCredentialFormFor formOptions

    @form.on 'Cancel', @bound 'cancel'

    @form.on 'CredentialUpdated', =>
      new KDNotificationView { title : 'Credential was updated.', type: 'mini' }
      @cancel()
