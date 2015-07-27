kd                              = require 'kd'
globals                         = require 'globals'
remote                          = require('app/remote').getInstance()

_                               = require 'lodash'
hljs                            = require 'highlight.js'
jsyaml                          = require 'js-yaml'
Encoder                         = require 'htmlencode'
dateFormat                      = require 'dateformat'

whoami                          = require 'app/util/whoami'
FSHelper                        = require 'app/util/fs/fshelper'
showError                       = require 'app/util/showError'
applyMarkdown                   = require 'app/util/applyMarkdown'

GitHub                          = require 'app/extras/github/github'
CustomViews                     = require 'app/commonviews/customviews'
IDEEditorPane                   = require 'ide/workspace/panes/ideeditorpane'
ComputeController_UI            = require 'app/providers/computecontroller.ui'

CredentialListItem              = require 'app/stacks/credentiallistitem'
AccountCredentialList           = require 'account/accountcredentiallist'
AccountCredentialListController = require 'account/views/accountcredentiallistcontroller'

StackRepoUserItem               = require 'app/stacks/stackrepouseritem'
StackTemplateList               = require 'app/stacks/stacktemplatelist'
StackTemplateListController     = require 'app/stacks/stacktemplatelistcontroller'


module.exports = class StacksCustomViews extends CustomViews

  # This will be used if stack template is not defined yet
  DEFAULT_TEMPLATE = """
  {
    "provider": {
      "aws": {
        "access_key": "${var.access_key}",
        "secret_key": "${var.secret_key}"
      }
    },
    "resource": {
      "aws_instance": {
        "example": {
          "instance_type": "t2.micro",
          "ami": ""
        }
      }
    }
  }
  """

  @STEPS         =
    CUSTOM_STACK : [
        { title  : 'Select Provider' }
        { title  : 'Credentials' }
        { title  : 'Bootstrap' }
        { title  : 'Define your Stack' }
        { title  : 'Complete' }
      ]
    REPO_FLOW    : [
        { title  : 'Select Repo' }
        { title  : 'Locate File' }
        { title  : 'Fetch Template' }
        { title  : 'Credentials' }
        { title  : 'Bootstrap' }
        { title  : 'Stack Details' }
        { title  : 'Complete' }
      ]


  parseTerraformOutput = (response) ->

    # An example of a valid stack template
    # ------------------------------------
    # title: "Default stack",
    # description: "Koding's default stack template for new users",
    # machines: [
    #   {
    #     "label" : "koding-vm-0",
    #     "provider" : "koding",
    #     "instanceType" : "t2.micro",
    #     "provisioners" : [
    #         "devrim/koding-base"
    #     ],
    #     "region" : "us-east-1",
    #     "source_ami" : "ami-a6926dce"
    #   }
    # ],

    out = machines: []

    {machines} = response

    for machine, index in machines

      {label, provider, region} = machine
      {instance_type, ami} = machine.attributes

      out.machines.push {
        label, provider, region
        source_ami   : ami
        instanceType : instance_type
        provisioners : [] # TODO what are we going to do with provisioners? ~ GG
      }

    console.info "[parseTerraformOutput]", out.machines

    return out.machines


  fetchGithubRepos = (options, callback) ->

    { oauth_data } = options
    { Github }     = remote.api

    Github.api method: 'user.getOrgs', (err, orgs) ->

      kd.warn err  if err

      orgs ?= []

      # to make identical users and orgs assigning
      # username to login field as well
      oauth_data.login = oauth_data.username
      users = [oauth_data]

      Github.api
        method  : 'search.repos'
        options :
          q     : "user:#{oauth_data.login}+fork:true"
          type  : 'all'
          sort  : 'updated'
          order : 'desc'

      , (err, repos) ->

        users.first.err   = err
        users.first.repos = repos?.items ? []

        callback null, {orgs, users}


  handleCheckTemplate = (options, callback) ->

    { stackTemplate } = options
    { computeController } = kd.singletons

    computeController.getKloud()
      .checkTemplate { stackTemplateId: stackTemplate._id }
      .nodeify callback


  fetchRepoFile = (options, callback) ->

    { Github } = remote.api
    { repo, location, ref } = options

    Github.api
      method  : 'repos.getContent'
      options :
        repo  : repo.name
        user  : repo.owner.login
        path  : location
        ref   : ref

    , callback


  updateStackTemplate = (data, callback) ->

    { template, templateDetails, credential
      title, stackTemplate, machines } = data

    title     or= 'Default stack template'
    credentials = [credential.publicKey]  if credential

    if stackTemplate
      dataToUpdate = if machines \
        then {machines} else {title, template, credentials, templateDetails}
      stackTemplate.update dataToUpdate, (err) ->
        callback err, stackTemplate
    else
      remote.api.JStackTemplate.create {
        title, template, credentials, templateDetails
      }, callback


  setGroupTemplate = (stackTemplate, callback) ->

    { groupsController } = kd.singletons

    currentGroup = groupsController.getCurrentGroup()
    { slug }     = currentGroup

    if slug is 'koding'
      message = 'Setting stack template for koding is disabled'
      new kd.NotificationView title: message
      return callback {message}

    currentGroup.modify stackTemplates: [ stackTemplate._id ], (err) ->
      return callback err  if err

      new kd.NotificationView
        title: "Group (#{slug}) stack has been saved!"

      callback()


  fetchAndShowCredentialData = (credential, outputView) ->

    outputView.addContent 'Fetching latest data...'

    credential.fetchData (err, data) ->

      if err
        outputView.addContent 'Failed: ', err.message
        return

      cred = JSON.stringify data.meta, null, 2
      outputView
        .addContent cred
        .addContent 'You can continue to next step.'
        .emit 'BootstrappingDone'


  handleBootstrap = (outputView, credential, button) ->

    outputView.addContent 'Bootstrapping started...'

    publicKeys = [credential.publicKey]

    { computeController } = kd.singletons

    computeController.getKloud()

      .bootstrap { publicKeys }

      .then (response) ->

        if response
          outputView.addContent 'Bootstrap completed successfully'
          fetchAndShowCredentialData credential, outputView
        else
          outputView.addContent 'Bootstrapping completed but something went wrong.'

        console.log '[KLOUD:Bootstrap]', response

      .catch (err) ->

        outputView.addContent 'Bootstrapping failed:', err.message
        console.warn '[KLOUD:Bootstrap:Fail]', err

      .finally button.bound 'hideLoader'


  handleNewCredential = (views, provider, button) ->

    {controller} = views.credentialList
    view = controller.getView()
    button.disable()
    view.hide()

    form = controller.showAddCredentialFormFor provider
    form.on 'Cancel', view.bound   'show'
    form.on 'Cancel', button.bound 'enable'

    kd.utils.defer -> form.inputs.title?.focus()

    # After adding credential, we are sharing it with the current
    # group, so anyone in this group can use this credential ~ GG
    form.on 'CredentialAdded', (credential) ->
      {slug} = kd.singletons.groupsController.getCurrentGroup()
      credential.shareWith {target: slug}, (err) ->
        console.warn 'Failed to share credential:', err  if err
        button.enable()
        view.show()


  analyzeTemplate = (content) ->

    valid       =  yes

    try
      obj       = JSON.parse content
      providers = Object.keys obj.provider
    catch e
      message   = "We've failed to parse the template, please make sure
                   you are providing a valid template like described
                   <a href=learn.koding.com target=_blank>here</a>."
      valid     = no

    if valid
      list      = ''
      list     += "<li>#{pr}\n" for pr in providers

      message   = "Based on the template you will need to enter
                   credetentials for the following providers; <br/>
                   #{list}"

    return { message, valid, providers, obj, content }


  analyzeError = (err) ->

    return 'An unknown error occured'  unless err

    if err.code is 404
      return 'Template file not found at provided tag/branch'

    if err.message?
      details = "with following error: #{err.message}"

    return "Failed to fetch template #{details ? ''}"


  # Pass string or an object to show it in a modal ~ GG
  showJSON = (options = {}, json) ->

    unless typeof json is 'string'
      json = JSON.stringify json, null, 2

    json = hljs.highlight('json', json).value

    { curry } = kd.utils
    options.cssClass = curry 'has-markdown content-modal', options.cssClass

    if options.overlay
      options.overlayOptions = cssClass: 'second-overlay'

    options.content = "<pre><code>#{json}</code></pre>"

    return new kd.ModalView options


  jsonToYaml = (content) ->

    contentType     = 'json'

    try
      contentObject = JSON.parse content

      content       = jsyaml.safeDump contentObject
      contentType   = 'yaml'

    catch err
      console.error '[JsonToYaml]', err

    console.log '[JsonToYaml]', { content, contentType, err }

    return { content, contentType, err }


  yamlToJson = (content) ->

    contentType     = 'yaml'

    try
      contentObject = jsyaml.safeLoad content

      content       = JSON.stringify contentObject
      contentType   = 'json'
    catch err
      console.error '[YamlToJson]', err

    console.log '[YamlToJson]', { content, contentType, err }

    return { content, contentType, err }


  _.assign @views,


    mainLoader: (message) =>

      container = @views.container 'main-loader'
      container.addSubView new kd.LoaderView
        showLoader : yes
        size       :
          width    : 40
          height   : 40

      textView = @addTo container, text: message
      container.setTitle = textView.bound 'updatePartial'

      return container


    outputView: (options) =>

      options.cssClass = kd.utils.curry 'output-view', options.cssClass
      options.tagName  = 'pre'
      container        = @views.view options
      code             = @views.view tagName : 'code'

      container.addSubView code

      container.addContent = (content...) ->
        content = content.join ' '
        content = "[#{dateFormat Date.now(), 'HH:MM:ss'}] #{content}\n"
        code.setPartial hljs.highlight('profile', content).value
        return container

      container.setContent = (content...) ->
        content = content.join ' '
        code.updatePartial hljs.highlight('profile', content).value
        return container

      return container


    editorView: (options) =>

      kd.singletons.appManager.require 'IDE'

      {content} = options

      content   = Encoder.htmlDecode content
      file      = FSHelper.createFileInstance path: 'localfile:/stack.json'

      editorView = new IDEEditorPane {
        cssClass: 'editor-view'
        file, content, delegate: this
      }

      editorView.setCss background: 'black'

      return editorView


    button: (options) ->
      options.cssClass ?= ''
      new kd.ButtonView options


    menuButton: (options) ->

      {menu, callback} = options

      button    = null
      _menu     = null
      menuItems = {}

      Object.keys(menu).forEach (key) ->
        menuItems[key] =
          callback     : ->
            callback menu[key]
            _menu.destroy()

      options.callback = ->
        _menu = new kd.ContextMenu
          cssClass    : 'menu-button-menu'
          delegate    : button
          y           : button.getY() + button.getHeight()
          x           : button.getX() - 5
          width       : button.getWidth()
          arrow       :
            placement : 'top'
            margin    : -button.getWidth() / 2
        , menuItems

      button = new kd.ButtonView options

      return button


    navButton: (options, name) =>
      options.cssClass = kd.utils.curry 'solid compact light-gray nav', name
      options.title = name.capitalize()
      @views.button options


    navCancelButton: (options) =>
      options.cssClass = 'solid compact light-gray nav cancel'
      @views.button options


    input: (options, name) =>

      {label, value} = options

      new kd.FormViewWithFields
        fields: input: {name, label, defaultValue: value}


    repoList: (options) =>

      controller    = new kd.ListViewController
        viewOptions :
          itemClass : StackRepoUserItem
          cssClass  : 'repo-user-list'

      __view = controller.getListView()
      return { __view, controller }


    repoListView: (options) =>

      container    = @views.container 'repo-listview'
      loader       = @addTo container,
        mainLoader : 'Fetching repositories list...'

      fetchGithubRepos options, (err, repo_data) =>

        showError err

        loader.hide()

        views        = @addTo container,
          text       : "Github: Select a repository from your account"
          repoList   : options

        {controller, __view: repoList} = views.repoList

        {orgs, users} = repo_data
        controller.replaceAllItems users.concat orgs

        container.forwardEvent repoList, 'RepoSelected'

      return container


    credentialList: (options) =>

      { provider, stackTemplate } = options

      listView   = new AccountCredentialList
        itemClass   : CredentialListItem
        itemOptions : { stackTemplate }

      controller = new AccountCredentialListController
        view        : listView
        wrapper     : no
        scrollView  : no
        provider    : provider

      __view = controller.getView()
      return { __view, controller }


    providersView: (options) =>

      {providers, enabled} = options
      enabled  ?= providers

      container = @views.container 'providers'

      providers.forEach (provider) =>

        return  if provider in ['custom', 'managed']

        name = globals.config.providers[provider]?.name or provider

        @addTo container,
          button     :
            title    : name
            cssClass : provider
            disabled : provider not in enabled
            callback : ->
              container.emit 'ItemSelected', provider

      return container


    stepsHeader: (options) =>

      { title, index, selected } = options

      container = @views.container "#{if selected then 'selected' else ''}"

      @addTo container,
        text_step  : index
        text_title : title

      return container


    stepsHeaderView: (options) =>

      { steps, selected } = options

      container = @views.container 'steps-view'

      @addTo container, view :
        cssClass : 'vline'
        tagName  : 'cite'

      steps = steps.slice 0
      steps.forEach (step, index) =>

        step.index    = index + 1
        step.selected = selected? and selected is step.index

        @addTo container, stepsHeader: step

      return container


    initialView: (callback) =>

      container = @views.container 'stacktemplates'

      { groupsController } = kd.singletons
      currentGroup = groupsController.getCurrentGroup()

      views = @addTo container,
        text_header       : 'Compute Stack Templates'
        container_top     :
          text_intro      : "Stack Templates are awesome because when a user
                             joins your group you can preconfigure their work
                             environment by defining stacks.
                             Learn more about stacks"
          menuButton      :
            title         : 'Configure a Stack'
            cssClass      : 'solid compact green action'
            menu          :
              'Create from scratch' : 'create-new'
              'Use from repo'       : 'from-repo'
            callback      : callback
        stackTemplateList :
          group           : currentGroup

      templateList = views.stackTemplateList.__view
      templateList.on 'ItemSelected', (stackTemplate) ->
        callback 'edit-template', stackTemplate

      return container


    stackTemplateList: (options) ->

      listView   = new StackTemplateList
      controller = new StackTemplateListController
        view       : listView
        wrapper    : no
        scrollView : no

      __view = controller.getView()
      return { __view, controller }

    # STEPS --------------------------------------------------------------------

    stepSelectRepo: (options) =>

      {callback, cancelCallback, data, index, steps} = options
      container = @views.container 'step-select-repo'

      views     = @addTo container,
        stepsHeaderView   : {steps, selected: index}
        text              : "We need to locate your configuration file first so
                             that we can understand what we are going to do
                             when a user joins to your team.<br />
                             So please tell us where your stack configuration
                             file is."
        providersView     :
          providers       : ['github', 'bitbucket']
          enabled         : ['github']
        navButton_cancel  :
          callback        : cancelCallback

      views.providersView.on 'ItemSelected', (provider) ->

        whoami().fetchOAuthInfo (err, services) ->
          return  if showError err

          unless oauth = services?[provider]
            showError "You need to authenticate with #{provider} first."
            kd.singletons.router.handleRoute '/Admin/Integrations'
          else
            data.repo_provider = provider
            data.oauth_data    = oauth
            callback data

      return container


    stepLocateFile: (options) =>

      { callback, cancelCallback, data, steps, index } = options
      { repo_provider, oauth_data } = data

      container = @views.container 'step-view'

      views     = @addTo container,
        stepsHeaderView   : {steps, selected: index}
        repoListView      : { oauth_data }
        navCancelButton   :
          title           : '< Select another provider'
          callback        : ->
            cancelCallback data

      views.repoListView.on 'RepoSelected', (selected_repo) ->
        data.selected_repo = selected_repo
        callback data

      return container


    stepFetchTemplate: (options) =>

      { callback, cancelCallback, data, steps, index } = options
      { repo_provider, selected_repo }   = data

      container = @views.container 'step-view'
      container.setClass 'has-markdown'

      views     = @addTo container,
        stepsHeaderView   : {steps, selected: index}
        mainLoader        : 'Fetching template...'
        container         : 'output-container'
        navCancelButton   :
          title           : '< Select another template'
          callback        : ->
            cancelCallback data

      {mainLoader} = views

      fetchRepoFile selected_repo, (err, res) =>

        mainLoader.setTitle 'Parsing template...'

        if err
          content = analyzeError err
          message = "We've failed to fetch the template, from given branch/tag
                     with given file name. Please make sure you are providing
                     a valid template path like described
                     <a href=learn.koding.com target=_blank>here</a>."

        else if res?.content?

          content   = atob res.content
          template  = analyzeTemplate content
          {message} = template
          template.details = res

          if template.valid then @addTo container,
            button        :
              title       : 'Continue'
              cssClass    : 'solid compact green nav next'
              callback    : ->
                data.provider = 'aws' # Use the only supported provider for now ~ GG
                data.template = template
                callback data

        else

          content = 'Something went wrong, please try again.'


        {outputView} = @addTo views.container,

          container_top :
            text        : message
          outputView    :
            cssClass    : 'template-output'

        outputView.setContent content
        mainLoader.hide()


      return container


    stepSelectProvider: (options) =>

      {callback, cancelCallback, data, steps, index} = options
      container = @views.container 'step-provider'

      views     = @addTo container,
        stepsHeaderView : {steps, selected: index}
        text            : "You need to select a provider first"
        providersView   :
          providers     : Object.keys globals.config.providers
          enabled       : ['aws']
        navButton_cancel:
          callback      : cancelCallback

      views.providersView.on 'ItemSelected', (provider) ->
        data.provider = provider
        callback data

      return container


    stepSetupCredentials: (options) =>

      { data, callback, cancelCallback, steps, index } = options
      { provider, stackTemplate } = data

      container  = @views.container 'step-creds'
      views      = @addTo container,
        stepsHeaderView : {steps, selected: index}
        container_top   :
          text_intro    : "To be able to use this provider <strong>you need to
                           select a verified credential</strong> below, if you
                           don't have a verified credential you won't be able
                           to setup your stack for your team."
          button        :
            title       : 'Add New Credential'
            cssClass    : 'solid compact green action'
            callback    : ->
              handleNewCredential views, provider, this
        credentialList  : { provider, stackTemplate }
        navCancelButton :
          title         : '< Select another provider'
          callback      : ->
            cancelCallback data

      credentialList = views.credentialList.__view
      credentialList.on 'ItemSelected', (credential) ->
        data.credential = credential
        callback data

      return container


    stepBootstrap: (options) =>

      {callback, cancelCallback, data, steps, index} = options
      {provider, credential, stackTemplate} = data

      container = @views.container 'step-view'

      container.setClass 'has-markdown'

      views     = @addTo container,
        stepsHeaderView : {steps, selected: index}
        container       :
          mainLoader    : 'Checking bootstrap status...'
        navCancelButton :
          title         : '< Select another credential'
          callback      : -> cancelCallback data

      credential.isBootstrapped (err, state) =>

        views.container.destroySubViews()
        views.container.setClass 'output-container'

        {outputView} = @addTo views.container,

          container_top :
            text_intro  : "Bootstrapping for given credential is required.
                           With this process we will create necessary
                           settings on your #{provider} account.
                           Which you can see them from provider's control
                           panel as well."
            button      :
              title     : 'Bootstrap Now'
              cssClass  : \
                "solid compact green action #{if state then 'hidden' else ''}"
              loader    : yes
              callback  : ->
                outputView.show()
                handleBootstrap outputView, credential, this

          outputView    :
            cssClass    : 'bootstrap-output hidden'

        outputView.on 'BootstrappingDone', => @addTo container,
          button        :
            title       : 'Continue'
            cssClass    : 'solid compact green nav next'
            callback    : -> callback data

        if state
          outputView.show()
          outputView.addContent 'Bootstrapping completed for this credential'
          fetchAndShowCredentialData credential, outputView

      return container


    stepDefineStack: (options) =>

      {callback, cancelCallback, data, steps, index} = options
      {provider, credential, stackTemplate, template} = data or {}

      container = @views.container 'step-define-stack'

      if data.selected_repo? and template?
        {repo}          = data.selected_repo
        title           = repo.description
        content         = template?.content
        templateDetails =
          fileSha       : template.details.sha
          fileName      : template.details.name
          fileRepo      : repo.full_name
          fileRepoRef   : data.selected_repo.ref
          fileRepoPath  : data.selected_repo.location

      else
        title   = stackTemplate?.title or 'Default Template'
        content = stackTemplate?.template?.content
        templateDetails = null

      content or= DEFAULT_TEMPLATE

      views     = @addTo container,
        stepsHeaderView : {steps, selected: index}
        input_title     :
          label         : 'Stack Template Title'
          value         : title
        editorView      : {content}
        navCancelButton :
          title         : '< Boostrap Credential'
          callback      : -> cancelCallback data
        button_save     :
          title         : 'Save & Test >'
          cssClass      : 'solid compact green nav next'
          callback      : ->

            {title} = views.input_title.getData()
            templateContent = views.editorView.getValue()

            updateStackTemplate {
              template: templateContent, templateDetails
              credential, stackTemplate, title
            }, (err, _stackTemplate) ->
              return  if showError err

              data.stackTemplate = _stackTemplate
              callback data

      return container


    stepComplete: (options) =>

      {callback, cancelCallback, data, steps, index} = options
      {stackTemplate, credential, provider} = data

      container = @views.container 'step-complete'

      container.setClass 'has-markdown'

      views = @addTo container,
        stepsHeaderView : {steps, selected: index}
        container       :
          mainLoader    : 'Processing template...'

      handleCheckTemplate {stackTemplate}, (err, response) =>

        console.log '[KLOUD:checkTemplate]', err, response

        @addTo container,
          navCancelButton :
            title         : '< Edit Template'
            callback      : -> cancelCallback data

        views.container.destroySubViews()

        outputView   = @addTo views.container,
          outputView :
            cssClass : 'plan-output'

        if err or not response
          outputView
            .addContent 'Something went wrong with the template:'
            .addContent err?.message or 'No response from Kloud'
        else

          machines = parseTerraformOutput response

          outputView
            .addContent 'Template check complete succesfully'
            .addContent 'Following machines will be created:'
            .addContent JSON.stringify machines, null, 2
            .addContent 'Click Complete to set this stack as default stack'

          @addTo container,
            button_save     :
              title         : 'Complete'
              cssClass      : 'solid compact green nav next'
              callback      : ->
                updateStackTemplate {
                  stackTemplate, machines
                }, (err, stackTemplate) ->
                  return  if showError err
                  callback stackTemplate

      return container
