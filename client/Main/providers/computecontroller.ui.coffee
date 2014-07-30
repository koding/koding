class ComputeController.UI

  requiresLogin = do -> ({ message }, fn) -> (args...)->

    return unless KD.isLoggedIn()
      new KDNotificationView
        title: message

    fn args...


  @showProvidersModal = requiresLogin
    message: "You need to login to create a new machine."
  , (stack)->

    new KDModalView
      title    : 'Add Virtual Machine'
      cssClass : 'provider-modal'
      view     : new ProviderView {stack}
      width    : 800
      height   : 600
      overlay  : yes


  @generateAddCredentialFormFor = (provider)->

    fields          =
      title         :
        label       : "Title"
        placeholder : "title for this credential"

    Providers = ComputeController.providers
    credentialFields = Object.keys Providers[provider].credentialFields

    unless credentialFields.length
      return

    credentialFields.forEach (field)->
      fields[field] = _.clone Providers[provider].credentialFields[field]
      fields[field].required = yes

    return form = new KDFormViewWithFields
      cssClass     : "form-view"
      fields       : fields
      buttons      :

        Save       :
          title    : "Add credential"
          type     : "submit"
          style    : "solid green medium"
          loader   : color : "#444444"
          callback : -> @hideLoader()

        Cancel     :
          style    : "solid medium"
          type     : "button"
          callback : -> form.emit "Cancel"

      callback     : (data)->

        { Save } = @buttons
        Save.showLoader()

        { title } = data
        delete data.title

        KD.remote.api.JCredential.create {
          provider, title, meta: data
        }, (err, credential)=>

          Save.hideLoader()

          unless KD.showError err
            @emit "CredentialAdded", credential


  @generateCreateInstanceForm: ->

    form = new KDFormViewWithFields

      cssClass          : "form-view"

      fields            :

        title           :
          label         : "Title"
          placeholder   : "title for this instance"
          validate      :
            rules       :
              required  : yes
            messages    :
              required  : "Title is required"

      buttons           :

        Save            :
          title         : "Create Instance"
          type          : "submit"
          style         : "solid green medium"
          loader        : color : "#444444"
          callback      : -> @hideLoader()

        Cancel          :
          style         : "solid medium"
          type          : "button"
          callback      : -> form.emit "Cancel"

      callback          : (data)->
        form.emit "Submit", data

  @askFor: (action, target, callback)->

    modal = KDModalView.confirm
      title       : "Remove machine"
      description : "Do you want to remove ?"
      ok          :
        title     : "Yes, remove"
        callback  : ->
          modal.destroy()
          callback()

  @askMachineForApp: (app, callback)->

    modal = new MachineListModal

    modal.once "MachineSelected", (machine, remember = no)->
      modal.off "KDModalViewDestroyed"
      callback null, machine, remember

    modal.once "KDModalViewDestroyed", ->
      callback
        name    : "NOMACHINE"
        message : "No machine selected"


  showInlineInformation = do ->

    information = null

    (provisioner, modal)->

      if provisioner?
        message = "Build script <strong>#{provisioner.slug}</strong> loaded. "
        unless KD.isMine provisioner
          message += """When you edit it, it won't change the original,
                        it will create your own copy of this build script."""
      else
        message = """This is a new build script. This bash script will be
                     executed as root when the machine is rebuilt."""

      information?.destroy?()
      information = new KDNotificationView
        container     : modal
        type          : "tray"
        content       : message
        duration      : 0
        closeManually : no


  @showBuildScriptEditorModal = (machine)->

    return  unless machine?

    ComputeController.reviveProvisioner machine, (err, provisioner)->

      return  if KD.showError err

      modal   = new EditorModal

        editor              :
          title             : "Build Script Editor"
          content           : provisioner?.content?.script or ""
          saveMessage       : "Build script saved"
          saveFailedMessage : "Couldn't save build script"

          saveCallback      : (script, modal)->

            if KD.isMine provisioner

              provisioner.update content: { script }, (err, res)->
                modal.emit if err then "SaveFailed" else "Saved"

            else

              {JProvisioner} = KD.remote.api
              JProvisioner.create
                type    : "shell"
                content : { script }
              , (err, newProvisioner)->

                return  if KD.showError err

                machine.jMachine.setProvisioner newProvisioner.slug, (err)->
                  modal.emit if err then "SaveFailed" else "Saved"

                  unless KD.showError err
                    machine.provisioners = [ newProvisioner.slug ]
                    provisioner          = newProvisioner

                    showInlineInformation provisioner, modal

      showInlineInformation provisioner, modal
