kd                   = require 'kd'
_                    = require 'underscore'
hljs                 = require 'highlight.js'
Encoder              = require 'htmlencode'

KDView               = kd.View
KDModalView          = kd.ModalView
KDCustomHTMLView     = kd.CustomHTMLView
KDNotificationView   = kd.NotificationView
KDCustomScrollView   = kd.CustomScrollView
KDFormViewWithFields = kd.FormViewWithFields

globals              = require 'globals'
remote               = require('../remote').getInstance()

isMine               = require 'app/util/isMine'
showError            = require 'app/util/showError'
isLoggedIn           = require 'app/util/isLoggedIn'
applyMarkdown        = require 'app/util/applyMarkdown'

TerminalModal        = require '../terminal/terminalmodal'

MissingDataView      = require './missingdataview'

{ jsonToYaml }       = require 'admin/views/stacks/yamlutils'


module.exports = class ComputeController_UI

  requiresLogin = do -> ({ message }, fn) -> (args...)->

    return unless isLoggedIn()
      new KDNotificationView
        title: message

    fn args...


  @generateAddCredentialFormFor = (options) ->

    { provider, requiredFields, defaultTitle, defaultValues, callback } = options

    defaultValues ?= []

    fields           =
      title          :
        label        : "Title"
        placeholder  : "title for this credential"
        defaultValue : defaultTitle or ''

    if provider in ['custom', 'userInput'] and requiredFields
      credentialFields = {}

      for field in requiredFields
        credentialFields[field] =
          label : field.capitalize()

      currentProvider  = { credentialFields }

    else
      Providers        = globals.config.providers
      currentProvider  = Providers[provider]

    credentialFields   = Object.keys currentProvider.credentialFields

    return  unless credentialFields.length

    selectOptions = []

    credentialFields.forEach (field) ->

      _field = fields[field] = _.clone currentProvider.credentialFields[field]

      _field.required     = yes
      _field.defaultValue = defaultValues[field]  if defaultValues[field]?

      if _field.type is 'selection'
        { values }           = _field
        _field.itemClass     = kd.SelectBox
        _field.defaultValue ?= values.first.value

        selectOptions.push { field, values }


    buttons      =
      Save       :
        title    : "Save"
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

        fields[field].defaultValue = defaultValues[field]  if defaultValues[field]?


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
      callback     : (data) ->

        @buttons.Save.showLoader()

        { title } = data
        delete data.title

        # Remove fields which has no value in it
        for field, value of data
          delete data[field]  if value is ''

        if callback
          callback title, data
        else
          remote.api.JCredential.create {
            provider, title, meta: data
          }, (err, credential) =>
            @buttons.Save.hideLoader()

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
            You will lose all your files, workspaces, collaboration sessions and data but your VM
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
        deleteStack :
          title   : "Delete Stack?"
          message : "
            If you choose to proceed, this stack and all the VMs will be
            deleted, and you won't be able to revert this.
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
              <li> collaboration sessions </li>
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


  @requestMissingData = (options, callback) ->

    missingDataView = new MissingDataView options

    modal = new kd.ModalView
      cssClass       : 'AppModal AppModal--admin'
      title          : 'Build Requirements'
      width          : 630
      overlay        : yes
      view           : missingDataView
      overlayClick   : no
      overlayOptions : cssClass: 'second-overlay'

    modal.overlay.on 'click', ->
      lc = missingDataView.listController
      modal.destroy()  unless lc.isAddCredentialFormOpen

    missingDataView.on 'RequirementsProvided', ({ stack, credential }) ->
      callback { stack, credential }
      modal.destroy()


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


  @showComputeError = (options) ->

    { stack, errorMessage, title, subtitle, cssClass, message } = options

    cssClass ?= ''
    message   = if message then "<div class='message'>#{message}</div>" else ''

    modal     = new kd.ModalView
      title          : title    ? "An error occured"
      subtitle       : subtitle ? ""
      draggable      : no
      height         : 600
      cssClass       : "AppModal AppModal--admin has-markdown
                        compute-error-modal #{cssClass}"
      overlay        : yes
      overlayOptions :
        cssClass     : 'second-overlay'

    content      = (hljs.highlight 'profile', errorMessage).value

    errorDetails = new KDView
    if message
      errorDetails.setClass 'with-message'
      errorDetails.addSubView new KDCustomHTMLView
        partial: "#{message}"

    errorDetails.addSubView scrollView = new KDCustomScrollView
    scrollView.wrapper.addSubView new KDCustomHTMLView
      cssClass : 'error-content'
      partial  : """
        <div class='content'>
          <pre><code>#{content}</code></pre>
        </div>
      """

    if stack

      modal.addSubView tabView = new kd.TabView hideHandleCloseIcons: yes

      tabView.addPane new kd.TabPaneView
        name : 'Error Details'
        view : errorDetails

      # Fetch stack template, coming from remote.cacheable ~ GG
      { computeController } = kd.singletons
      computeController.fetchBaseStackTemplate stack, (err, template) ->

        return kd.warn err  if err

        {content} = template.template
        content   = Encoder.htmlDecode content or ''
        content   = (hljs.highlight 'coffee', (jsonToYaml content).content).value

        stackTemplate = new KDCustomScrollView
        stackTemplate.wrapper.addSubView new KDCustomHTMLView
          partial  : "<pre><code>#{content}</code></pre>"

        tabView.addPane new kd.TabPaneView
          name       : 'Stack Template'
          view       : stackTemplate

        tabView.showPaneByIndex 0

    else

      modal.addSubView errorDetails

