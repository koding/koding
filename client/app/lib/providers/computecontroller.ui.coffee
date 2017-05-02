kd                   = require 'kd'
_                    = require 'underscore'
hljs                 = require 'highlight.js'
Encoder              = require 'htmlencode'

KDView               = kd.View
KDCustomHTMLView     = kd.CustomHTMLView
KDNotificationView   = kd.NotificationView
KDCustomScrollView   = kd.CustomScrollView
KDFormViewWithFields = kd.FormViewWithFields

globals              = require 'globals'
remote               = require('../remote')

isMine               = require 'app/util/isMine'
showError            = require 'app/util/showError'
isLoggedIn           = require 'app/util/isLoggedIn'
applyMarkdown        = require 'app/util/applyMarkdown'
doXhrRequest         = require 'app/util/doXhrRequest'
ContentModal         = require 'app/components/contentModal'

MissingDataView      = require './missingdataview'

{ jsonToYaml }       = require 'app/util/stacks/yamlutils'


module.exports = class ComputeControllerUI

  do -> ({ message }, fn) -> (args...) ->

    return unless isLoggedIn()
      new KDNotificationView
        title: message


    fn args...


  KNOWN_FIELD_TYPES   =
    'ssh_private_key' : 'textarea'

  showPrivateKeyWarning = (privateKey) ->

    new ContentModal
      title           : 'Please save private key content'
      content         : applyMarkdown "
                         This stack only requires public key which means
                         private key of this public key is not going to be
                         stored, please take a copy of following private key.
                         \n
                         **You won't be able to access this private key later**
                         ```\n#{privateKey}\n```
      "
      cssClass        : 'has-markdown content-modal'
      width           : 530
      overlay         : yes
      overlayClick    : yes
      overlayOptions  :
        cssClass      : 'second-overlay'


  hasStackRequiredField = (requiredFields, field) ->

    return yes  if field in requiredFields
    return (item for item in requiredFields when item.name is field).length > 0


  injectCustomActions = (requiredFields, buttons, callback) ->

    if hasStackRequiredField requiredFields, 'ssh_public_key'

      buttons['Auto Generate SSH Keys'] =
        style    : 'solid medium green'
        type     : 'button'
        loader   : yes
        tooltip  :
          title  : 'This stack requires SSH keys that you
                    can automatically create one from here'
        callback : ->

          endPoint = '/api/social/sshkeys'
          type     = 'GET'

          doXhrRequest { endPoint, type }, (err, res) =>

            @hideLoader()
            return  if showError err

            unless hasStackRequiredField requiredFields, 'ssh_private_key'
              showPrivateKeyWarning res.private

            callback
              'ssh_public_key'  : res.public
              'ssh_private_key' : res.private

    return buttons


  @generateAddCredentialFormFor = (options, noCredFound = no) ->

    { provider, requiredFields, defaultTitle, defaultValues, callback } = options

    defaultValues ?= []

    fields           =
      title          :
        label        : 'Title'
        placeholder  : 'Title for this credential'
        defaultValue : defaultTitle or ''
        required     : yes

    if provider in ['custom', 'userInput'] and requiredFields
      credentialFields = {}

      for field in requiredFields
        name = field.name ? field
        continue  if name.indexOf('__') is 0
        type = field.type ? KNOWN_FIELD_TYPES[field] ? 'text'
        { values } = field
        credentialFields[name] = {
          label: name.capitalize()
          type
          values
        }

      currentProvider  = { credentialFields }

    else
      Providers        = globals.config.providers
      currentProvider  = Providers[provider]

    credentialFields   = Object.keys currentProvider.credentialFields

    return  unless credentialFields.length

    selectOptions = []

    credentialFields.forEach (field) ->

      _field = fields[field] = _.clone currentProvider.credentialFields[field]

      _field.required    ?= yes
      _field.defaultValue = defaultValues[field]  if defaultValues[field]?

      if _field.type is 'selection'
        { values }           = _field
        _field.itemClass     = kd.SelectBox
        _field.defaultValue ?= values.first.value

        selectOptions.push { field, values }

    buttons      =
      Save       :
        title    : 'Save'
        type     : 'submit'
        style    : 'solid primary green compact save-btn'
        loader   : { color : '#444444' }
        callback : -> @hideLoader()

      Cancel     :
        style    : 'solid compact cancel'
        type     : 'button'
        callback : -> form.emit 'Cancel'

    if requiredFields
      buttons = injectCustomActions requiredFields, buttons, (generatedKeys) ->
        for own field, input of form.inputs
          input.setValue data  if data = generatedKeys[field]

    # Add advanced fields into form
    if advancedFields = currentProvider.advancedFields
      advancedFields.forEach (field) ->
        fields[field] ?=
          label        : field.capitalize()
          placeholder  : field

        fields[field].cssClass = 'advanced-field'
        fields[field].required = no
        fields[field].defaultValue = defaultValues[field]  if defaultValues[field]?


      buttons['Advanced Mode'] =
        title    : 'Advanced Mode'
        style    : 'solid compact advanced-mode-btn'
        type     : 'button'
        callback : ->
          form.toggleClass 'in-advanced-mode'
          if @buttonTitle is 'Advanced Mode'
          then @setTitle 'Basic Mode'
          else @setTitle 'Advanced Mode'


    kiteQueryPath = new kd.View
      cssClass : 'formline help-line'
      partial : "<a href='https://www.koding.com/docs/creating-a-vagrant-stack'>Where do I get my Kite Query ID?</a>"

    form = new KDFormViewWithFields
      cssClass     : 'form-view'
      fields       : fields
      callback     : (data) ->

        @buttonField.buttons.Save.showLoader()

        { title } = data
        delete data.title

        # Remove fields which has no value in it
        # Trim value of fields which has value
        for field, value of data
          data[field] = value.trim()  if typeof value is 'string'
          delete data[field]  if value is ''

        if callback
          callback title, data
        else
          remote.api.JCredential.create {
            provider, title, meta: data
          }, (err, credential) =>
            @buttonField.buttons.Save.hideLoader()

            unless showError err
              @emit 'CredentialAdded', credential, noCredFound

    form.addSubView kiteQueryPath  if currentProvider.name is 'Vagrant'
    form.createButtons buttons

    selectOptions.forEach (select) ->
      { field, values } = select
      form.inputs[field].setSelectOptions values

    return form


  @generateCreateInstanceForm: ->

    form = new KDFormViewWithFields

      cssClass          : 'form-view'

      fields            :

        title           :
          label         : 'Title'
          placeholder   : 'Title for this instance'
          validate      :
            rules       :
              required  : yes
            messages    :
              required  : 'Title is required'

      buttons           :

        Save            :
          title         : 'Create Instance'
          type          : 'submit'
          style         : 'solid green medium'
          loader        : { color : '#444444' }
          callback      : -> @hideLoader()

        Cancel          :
          style         : 'solid light-gray medium'
          type          : 'button'
          callback      : -> form.emit 'Cancel'

      callback          : (data) ->
        form.emit 'Submit', data


  @askFor: (action, options, callback) ->

    { force, machine, dontAskAgain } = options

    machine     ?= {}
    { provider } = machine
    machineName  = machine.getName?() ? 'a machine'

    return callback()  if force

    tasks         =
      default     :
        reinitStack :
          title   : 'YOUR DATA WILL BE LOST!'
          message : '
            If you re-initialize this stack, the stack and all of its VMs will be
            re-initialized from the latest revision of this stack.
            You will lose all of your existing VMs and your data therein.
          '
          button  : 'Proceed'
        deleteStack :
          title   : 'Destroy Stack'
          message : "
            <p>If you choose to proceed, this stack and all the VMs will be
            destroyed, and you won't be able to revert this.</p>

            <p>Any existing data will be lost including existing files,
            VMs and anything provided by this stack.</p>
          "
          button  : 'Proceed'
        permissionFix  :
          title        : "Permission fix required for #{machineName}"
          message      : "
            <p>You don't have access to this Machine (<strong>#{machineName}</strong>).
            It belonged to <strong>@#{machine.meta?.oldOwner}</strong></p>

            <p>This is because you removed this user from your team.
            You need to fix permissions to proceed.</p>
          "
          button       : 'Fix Permissions'
          buttonColor  : 'green'
          dontAskAgain : dontAskAgain ? yes
        forceDeleteStack :
          title   : 'Delete Stack data'
          message : "
            <p>If you choose to proceed, all of the meta data and related
            information for this stack will be removed from Koding.</p>

            <p><strong>
              WARNING! This action won't destroy created resources on your
              stack provider, you need to perform a cleanup for those resources
              (such as VMs, domains, security groups etc.) manually.
            </strong></p>

            <p>With this action you'll remove the connection between
            this stack on Koding and related resources on your stack provider.</p>

            <p>Do you want to continue?</p>
          "
          button  : 'Proceed'
        destroy   :
          title   : 'Remove VM'
          message : '
            <p>Terminating this VM will destroy all of its:</p>
              <br/>
              <li> files and data </li>
              <li> running services </li>
              <li> settings </li>
              <li> custom domains (if any) </li>
              <li> collaboration sessions </li>
              <br/>
            <p>This action cannot be reversed!
            Are you sure you want to proceed?</p>
          '
          button  : 'Yes, remove'
        dontWarnMe:
          title   : 'Are you sure?'
          message : '<h2>By clicking Yes, You will not receive anymore update for this stack.</h2>'
          button  : 'Yes'
        enableTeamOAuth :
          title   : 'Do you want to setup as organization token?'
          message : applyMarkdown "
            In order to use and share GitHub organization tokens with admins
            you can set a team token for your team. For this, you need to be
            organization admin on GitHub and a team admin on Koding. \n\n

            You will need to allow `#{options.scope}` scopes with your
            integration. \n\n

            Do you want to enable your GitHub integration with these scopes or
            do you want to setup this integration as a regular user?
          "
          button  : 'Setup as Organization'
          cancel  : 'Setup as User'
        disableTeamOAuth :
          title   : 'Do you want to disable organization token?'
          message : applyMarkdown '
            Currently your GitHub token is also set as default for team
            integration, if you continue, this integration will be removed
            as well.\n\n

            Do you want to continue?
          '
          button  : 'Yes, Disable Integration'
      managed     :
        destroy   :
          title   : 'Delete Machine from Koding'
          message : applyMarkdown '
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

            Are you sure you want to proceed?'
          button  : 'Yes'


    task = tasks[provider]?[action] ? tasks.default[action]

    throw { message: "Failed to find action #{action}" }  unless task

    { title, message, button, cancel, buttonColor, dontAskAgain } = task

    buttonColor ?= 'red'
    dontAskAgain = 'hidden'  if not dontAskAgain

    modal = new ContentModal
      width          : 600
      title          : title ? 'Remove'
      cssClass       : 'has-markdown content-modal'
      attributes     :
        testpath     : action
      content        : """
        <div class='modalformline'>
          <p>#{message ? "Do you want to remove ?"}</p>
        </div>
      """
      overlay        : yes
      buttons        :
        cancel       :
          title      : cancel ? 'Cancel'
          style      : 'solid cancel medium'
          type       : 'button'
          callback   : ->
            modal.destroy()
            callback { confirmed: no, cancelled: yes }
        ok           :
          title      : button ? 'Yes, remove'
          style      : 'solid medium'
          callback   : ->
            modal.destroy()
            callback { confirmed: yes }
        dontAskAgain :
          title      : "Don't ask this again"
          style      : "solid medium #{dontAskAgain}"
          type       : 'button'
          callback   : ->
            modal.destroy()
            callback { dontAskAgain: yes }

    cancelledCallback = -> callback { confirmed: no, cancelled: yes }
    modal.once 'ModalCancelled', cancelledCallback
    modal.overlay.on 'click',    cancelledCallback

    return modal


  @requestMissingData = (options, callback) ->

    missingDataView = new MissingDataView options

    modal = new kd.ModalView
      cssClass       : 'AppModal AppModal--admin'
      title          : 'Build Requirements'
      width          : 630
      overlay        : yes
      attributes     :
        testpath     : 'BuildRequirementsModal'
      view           : missingDataView
      overlayClick   : no
      overlayOptions : { cssClass: 'second-overlay' }

    modal.overlay.on 'click', ->
      lc = missingDataView.listController
      modal.destroy()  unless lc.isAddCredentialFormOpen

    missingDataView.on 'RequirementsProvided', ({ stack, credential }) ->
      callback { stack, credential }
      modal.destroy()


  showInlineInformation = do ->

    information = null

    (provisioner, modal) ->

      if provisioner?
        message = "Build script <strong>#{provisioner.slug}</strong> loaded. "
        unless isMine provisioner
          message += """When you edit it, it won't change the original,
                        it will create your own copy of this build script."""
      else
        message = '''This is a new build script. This bash script will be
                     executed as root when the machine is rebuilt.'''

      information?.destroy?()
      information = new KDNotificationView
        container     : modal
        type          : 'tray'
        content       : message
        duration      : 0
        closeManually : no


  @showCredentialDetails = (options = {}, callback = kd.noop) ->

    { credential, cssClass } = options

    unless credential
      kd.warn 'No credential passed'
      return callback null

    credential.fetchData (err, data) ->
      return callback err  if showError err

      { meta } = data

      delete meta.__rawContent
      meta = _.mapValues meta, (val) -> _.unescape val
      meta.identifier = credential.identifier

      cred = JSON.stringify meta, null, 2
      cred = hljs.highlight('json', cred).value

      new kd.ModalView
        title : credential.title
        subtitle : credential.provider
        cssClass : kd.utils.curry 'has-markdown credential-modal', cssClass
        overlay : yes
        overlayOptions :
          cssClass : 'second-overlay'
        content : "<pre><code>#{cred}</code></pre>"

      callback data


  @showComputeError = (options) ->

    { stack, errorMessage, title, subtitle, message, cssClass } = options

    if /^invalid bootstrap metadata for/.test errorMessage
      errorMessage = """
        Failed to complete request due to error with the provided credential.
        Please contact with your team admin.

        #{errorMessage}
      """

    message = ''  unless message

    modal = new ContentModal
      title : title ? 'An error occured'
      draggable : no
      width : 600
      cssClass : "has-markdown content-modal #{cssClass}"
      overlay : yes

    content = (hljs.highlight 'profile', errorMessage).value

    errorDetails = new KDView
      tagName : 'main'
      cssClass: 'main-container'
    errorDetails.unsetClass 'kdview'
    if message
      errorDetails.setClass 'with-message'
      errorDetails.addSubView new KDCustomHTMLView
        tagName: 'p'
        partial: "#{message}"

    errorDetails.addSubView scrollView = new KDCustomScrollView
    scrollView.wrapper.addSubView new KDCustomHTMLView
      tagName  : 'p'
      cssClass : 'error-content'
      partial  : """
        <div class='content'>
          <pre><code>#{content}</code></pre>
        </div>
      """

    if stack
      modal.addSubView tabViewWrapper = new kd.CustomHTMLView
        tagName : 'main'
        cssClass : 'main-container'
      tabViewWrapper.addSubView tabView = new kd.TabView { hideHandleCloseIcons: yes }

      tabView.addPane new kd.TabPaneView
        name : 'Error Details'
        view : errorDetails

      # Fetch stack template, coming from remote.cacheable ~ GG
      { computeController } = kd.singletons
      computeController.fetchBaseStackTemplate stack, (err, template) ->

        return kd.warn err  if err or not template

        { content } = template.template
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


  createConfirmationModal = (callback) ->

    modal = new ContentModal
      cssClass     : 'content-modal ShareConfirmationModal'
      overlay      : yes
      title        : 'Sharing Credentials'
      content      : '''
        <h2>Do you really want to share your own credentials?</h2>
        <p>When you share your own credentials with your team,
        they will be able to create resources with it. If you don’t share,
        your team members will need to put their own credentials.</p>
      '''
      buttons      :
        cancel     :
          title    : 'No'
          cssClass : 'kdbutton solid medium'
          callback : ->
            callback { shareStack: yes, shareCredential: no }
            modal.destroy()
        ok         :
          title    : 'Yes'
          loader   : yes
          cssClass : 'kdbutton solid medium'
          callback : ->
            callback { shareStack: yes, shareCredential: yes, modal }


  @createShareModal = (callback, force = no) ->

    return callback yes  if force

    content = new kd.CustomHTMLView
      partial  : '''
        <div class="background"></div>
        <h1>Share your stack template with your team members</h1>
        <p>When you share your stack template, we will notify team members.</p>
      '''
    content.addSubView checkboxWrapper = new kd.CustomHTMLView
      tagName  : 'p'
      cssClass : 'checkbox-wrapper'
    checkboxWrapper.addSubView checkbox = new kd.CustomCheckBox()
    checkbox.setValue yes
    checkboxWrapper.addSubView label = new kd.CustomHTMLView
      tagName  : 'span'
      partial  : 'Share the credentials I used for this stack with my team.'
      click    : -> checkbox.setValue not checkbox.getValue()

    modal = new ContentModal
      cssClass     : 'content-modal ShareModal'
      overlay      : yes
      width        : 700
      title        : 'Share Your Stack'
      content      : content
      buttons      :
        cancel     :
          title    : 'Cancel'
          cssClass : 'kdbutton solid medium'
          callback : ->
            callback { shareStack: no, shareCredential: no }
            modal.destroy()
        share      :
          title    : 'Share With the Team'
          loader   : yes
          cssClass : 'kdbutton solid medium'
          callback : ->
            if checkbox.getValue()
              modal.destroy()
              createConfirmationModal callback
            else
              callback { shareStack: yes, shareCredential: no, modal }
