kd                  = require 'kd'
KDModalView         = kd.ModalView
KDCustumScrollView  = kd.CustomScrollView


module.exports = class AccountCredentialEditModal extends KDModalView


  constructor: (options = {}, data) ->

    options.cssClass  = kd.utils.curry 'credential-edit', options.cssClass
    options.title   or= 'Edit Credential'

    super options, data

    { ui } = kd.singletons.computeController

    formOptions               = {}
    formOptions.provider      = options.provider
    formOptions.defaultValues = data.meta
    formOptions.defaultTitle  = data.title

    @addSubView @scrollView = new KDCustumScrollView
    @scrollView.wrapper.addSubView @form = ui.generateAddCredentialFormFor formOptions

    @form.on 'Cancel', @bound 'cancel'
