kd                   = require 'kd'
_                    = require 'underscore'
KDModalView          = kd.ModalView
KDNotificationView   = kd.NotificationView
KDFormViewWithFields = kd.FormViewWithFields

globals              = require 'globals'
remote               = require('../remote').getInstance()

isMine               = require 'app/util/isMine'
showError            = require 'app/util/showError'
isLoggedIn           = require 'app/util/isLoggedIn'
applyMarkdown        = require 'app/util/applyMarkdown'

ProviderView         = require './providerview'
TerminalModal        = require '../terminal/terminalmodal'


module.exports = class ComputeController_UI

  requiresLogin = do -> ({ message }, fn) -> (args...)->

    return unless isLoggedIn()
      new KDNotificationView
        title: message

    fn args...


  @showProvidersModal = requiresLogin
    message: "You need to login to create a new VM."
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

    Providers        = globals.config.providers
    currentProvider  = Providers[provider]
    credentialFields = Object.keys currentProvider.credentialFields

    unless credentialFields.length
      return

    selectOptions = []

    credentialFields.forEach (field) ->

      _field = fields[field] = _.clone currentProvider.credentialFields[field]
      _field.required = yes

      if _field.type is 'selection'
        {values}             = _field
        _field.itemClass     = kd.SelectBox
        _field.defaultValue ?= values.first.value
        selectOptions.push { field, values }

    buttons      =
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

    # Add advanced fields into form
    if advancedFields = currentProvider.advancedFields
      advancedFields.forEach (field) ->
        fields[field] =
          label       : field.capitalize()
          placeholder : field
          cssClass    : 'advanced-field'

      buttons['Advanced Mode'] =
        style    : "solid medium"
        type     : "button"
        callback : ->
          form.toggleClass 'in-advanced-mode'
          @toggleClass 'green'

    form = new KDFormViewWithFields
      cssClass     : "form-view"
      fields       : fields
      buttons      : buttons
      callback     : (data)->

        { Save } = @buttons
        Save.showLoader()

        { title } = data
        delete data.title

        # Remove fields which has no value in it
        for field, value of data
          delete data[field]  if value is ''

        remote.api.JCredential.create {
          provider, title, meta: data
        }, (err, credential)=>

          Save.hideLoader()

          unless showError err
            @emit "CredentialAdded", credential

    selectOptions.forEach (select) ->
      { field, values } = select
      form.inputs[field].setSelectOptions values

    return form


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
          style         : "solid light-gray medium"
          type          : "button"
          callback      : -> form.emit "Cancel"

      callback          : (data)->
        form.emit "Submit", data

  @askFor: (action, options, callback) ->

    {force, machine, resizeTo} = options
    machine ?= {}

    if resizeTo?
      resizeFrom = machine.jMachine.meta?.storage_size or 3

      # If same value requested for resize we will ask this operation
      # to kloud, if somehow resize fails this help us to recover last state ~GG
      resizeDetails = if resizeTo is resizeFrom then "to #{resizeTo}GB" \
                      else "from #{resizeFrom}GB to #{resizeTo}GB"


    return callback()  if force

    {provider}    = machine

    tasks         =

      default     :
        resize    :
          title   : "Resize VM?"
          message : "
            If you choose to proceed, this VM will be resized #{resizeDetails}.
            During the resize process, you will not be able to use the VM but
            all your files, workspaces and data will be safe.
          "
          button  : "Proceed"
        reinit    :
          title   : "Reinitialize VM?"
          message : "
            If you choose to proceed, this VM will be reset to default state.
            You will lose all your files, workspaces and data but your VM
            settings (VM aliases, sub-domains etc.) will not be lost.
          "
          button  : "Proceed"
        reinitStack :
          title   : "Reinitialize Stack?"
          message : "
            If you choose to proceed, this stack and all the VMs will be
            re-initialized from the latest revision of this stack.
            You will lose all of your existing files, workspaces, VMs and all
            of your data.
          "
          button  : "Proceed"
        reinitNoSnapshot :
          title   : "Cannot proceed with reinitialization!"
          message : "
            <p>The snapshot on which this VM was originally based has been
            deleted, so the system cannot reinitialize this VM.</p>

            <p>Instead, would you like to reinit using a standard VM image?
            Note: reinitializing will erase all files and folders on the VM
            right now but your VM settings (VM aliases, sub-domains etc.)
            will not be lost.</p>
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
      managed     :
        destroy   :
          title   : "Delete Machine from Koding?"
          message : applyMarkdown "
            Deleting this machine here will only remove its connection to
            your Koding account. All files and data will still be available
            on the actual machine.\n\n

            If you also wish to uninstall the Koding Connector Service from
            your machine, then please run this command there once you have
            clicked “Yes” below. We recommend you copy the command below
            before clicking “Yes”.\n

            ```bash\n
            sudo dpkg -P klient\n
            ```\n

            Are you sure you want to proceed?"
          button  : "Yes"

    task = tasks[provider]?[action] ? tasks.default[action]

    throw message: "Failed to find action #{action}"  unless task

    {title, message, button} = task

    modal = KDModalView.confirm
      title       : title   ? "Remove?"
      description : message ? "Do you want to remove ?"
      ok          :
        title     : button  ? "Yes, remove"
        style     : 'solid red medium'
        callback  : ->
          modal.destroy()
          callback()
      cancel      :
        style     : "solid light-gray medium"
        type      : "button"
        callback  : ->
          modal.destroy()

    modal.setClass 'has-markdown'

    return modal


  showInlineInformation = do ->

    information = null

    (provisioner, modal)->

      if provisioner?
        message = "Build script <strong>#{provisioner.slug}</strong> loaded. "
        unless isMine provisioner
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

    ComputeHelpers = require './computehelpers'
    ComputeHelpers.reviveProvisioner machine, (err, provisioner)->

      return  if showError err

      modal   = new EditorModal

        editor              :
          title             : "Build Script Editor"
          content           : provisioner?.content?.script or ""
          saveMessage       : "Build script saved"
          saveFailedMessage : "Couldn't save build script"

          saveCallback      : (script, modal)->

            if isMine provisioner

              provisioner.update content: { script }, (err, res)->
                modal.emit if err then "SaveFailed" else "Saved"

            else

              {JProvisioner} = remote.api
              JProvisioner.create
                type    : "shell"
                content : { script }
              , (err, newProvisioner)->

                return  if showError err

                machine.jMachine.setProvisioner newProvisioner.slug, (err)->
                  modal.emit if err then "SaveFailed" else "Saved"

                  unless showError err
                    machine.provisioners = [ newProvisioner.slug ]
                    provisioner          = newProvisioner

                    showInlineInformation provisioner, modal

      showInlineInformation provisioner, modal
