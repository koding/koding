kd                  = require 'kd'
KDModalView         = kd.ModalView
KDCustumScrollView  = kd.CustomScrollView
KDView              = kd.CustomHTMLView
KDNotificationView  = kd.NotificationView
showError           = require 'app/util/showError'


module.exports = class AccountCredentialEditModal extends KDModalView


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'credential-edit', options.cssClass
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

    @addSubView @wrapper = new KDView cssClass : 'stacks step-creds'

    @wrapper.addSubView @form = ui.generateAddCredentialFormFor formOptions

    @form.on 'Cancel', @bound 'cancel'

    @form.on 'CredentialUpdated', =>
      new KDNotificationView title : 'Credential was updated.', type: 'mini'
      @cancel()
