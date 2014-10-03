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

  @askFor: (action, target, force, callback)->

    return callback()  if force

    tasks =

      resize    :
        title   : "Resize VM?"
        message : "
          If you choose to proceed, this VM will be resized to 10Gb.
          You won't be able to use the vm during resize but all your files,
          workspaces and data will remain safe.
        "
        button  : "Proceed"
      reinit    :
        title   : "Reinitialize VM?"
        message : "
          If you choose to proceed, this VM will be reset to default state.
          You will loose all your files, workspaces and data but your VM
          settings (VM aliases, sub-domains etc.) will not be lost.
        "
        button  : "Proceed"
      destroy   :
        title   : "Remove VM?"
        message : "
          <p>Terminating this VM will destroy all of its:</p>
            <br/>
            <li> files and data </li>
            <li> workspaces </li>
            <li> running services </li>
            <li> settings </li>
            <li> custom domains (if any) </li>
            <br/>
          <p>This action cannot be reversed!
          Are you sure you want to proceed?</p>

        "
        button  : "Yes, remove"

    if tasks[action]?
      {title, message, button} = tasks[action]

    modal = KDModalView.confirm
      title       : title   ? "Remove?"
      description : message ? "Do you want to remove ?"
      ok          :
        title     : button  ? "Yes, remove"
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
