$                     = require 'jquery'
kd                    = require 'kd'
hljs                  = require 'highlight.js'
JView                 = require 'app/jview'
CodeSetupView         = require './codesetupview'
{ jsonToYaml }        = require 'app/util/stacks/yamlutils'
GetStartedView        = require './getstartedview'
ConfigurationView     = require './configurationview'
ProviderSelectionView = require './providerselectionview'
Tracker               = require 'app/util/tracker'
CustomLinkView        = require 'app/customlinkview'
CLONE_REPO_TEMPLATES  =
  github              : 'git clone git@github.com:your-organization/reponame.git'
  bitbucket           : 'git clone git@bitbucket.org/your-organization/reponame.git'
  gitlab              : 'git clone git@gitlab.com/your-organization/reponame.git'
  yourgitserver       : 'git clone git@yourgitserver.com/reponame.git'
PROVIDER_TEMPLATES    =
  aws                 :
    aws               :
      access_key      : '${var.aws_access_key}'
      secret_key      : '${var.aws_secret_key}'


module.exports = class OnboardingView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-onboarding main-content'

    super options, data

    @createViews()
    @createFooter()

    @bindPageEvents()


  createViews: ->

    @getStartedView        = new GetStartedView
    @codeSetupView         = new CodeSetupView          { cssClass: 'hidden' }
    @configurationView     = new ConfigurationView      { cssClass: 'hidden' }
    @providerSelectionView = new ProviderSelectionView  { cssClass: 'hidden' }

    @pages       = [ @getStartedView, @providerSelectionView, @configurationView, @codeSetupView ]
    @currentPage = @getStartedView

    @setClass 'get-started'


  bindPageEvents: ->

    @pages.forEach (page) => page.on 'UpdateStackTemplate', => @updateStackTemplate()

    @on 'PageNavigationRequested', @bound 'handlePageNavigationRequested'

    @getStartedView.on 'NextPageRequested', =>
      @unsetClass 'get-started'
      @emit 'PageNavigationRequested', 'next'

    @getStartedView.emit 'NextPageRequested'  if @getOption 'skipOnboarding'

    @providerSelectionView.on 'UpdateStackTemplate', @bound 'handleUpdateStackTemplate'

    @configurationView.tabView.on 'PaneAdded', => @codeSetupView.addPane()

    @configurationView.tabView.on 'PaneRemoved', =>
      @codeSetupView.tabView.removePane @codeSetupView.tabView.panes.last

    @configurationView.on 'InstanceTypeChanged', @bound 'handleInstanceTypeChanged'


  handlePageNavigationRequested: (direction) ->

    pageIndex  = @pages.indexOf @currentPage
    nextIndex  = if direction is 'next' then ++pageIndex else --pageIndex
    targetPage = @pages[nextIndex]

    # Temporary solution ~ GG
    selectedProvider  = @providerSelectionView.selected?.getOption 'provider'

    if direction is 'next' and selectedProvider is 'vagrant'
      @onboardingCompleted()
    else if targetPage
      @currentPage.hide()
      targetPage.show()
      @setClass 'get-started'  if targetPage is @getStartedView
      @currentPage = targetPage
    else
      @onboardingCompleted()


  handleUpdateStackTemplate: (isSelected) ->

    if isSelected
      @nextButton.enable()
      @skipLink.show()
    else
      @nextButton.disable()
      @skipLink.hide()


  handleInstanceTypeChanged: (type) ->

    for pane, index in @configurationView.tabView.panes
      label = @codeSetupView.tabView.panes[index]?.instanceTypeLabel
      label.updatePartial pane.instanceTypeSelectBox.getValue()  if label


  createFooter: ->

    @cancelButton = new kd.ButtonView
      cssClass : 'StackEditor-OnboardingModal--cancel'
      title    : 'CANCEL'
      callback : => @emit 'StackCreationCancelled'

    @backButton = new kd.ButtonView
      cssClass  : 'outline back'
      title     : 'Back'
      callback  : => @emit 'PageNavigationRequested', 'prev'

    @nextButton = new kd.ButtonView
      cssClass  : 'outline next'
      title     : 'Next'
      disabled  : yes
      callback  : => @emit 'PageNavigationRequested', 'next'

    @skipLink   = new CustomLinkView
      cssClass  : 'HomeAppView--button hidden'
      title     : 'SKIP GUIDE'
      click     : =>
        @destroy()
        selectedProvider = @providerSelectionView.selected?.getOption 'provider'
        if selectedProvider?
          options = { selectedProvider }
          if selectedProvider is 'vagrant'
            options.template = { content: @stackTemplate }
        Tracker.track Tracker.STACKS_SKIP_SETUP
        @emit 'StackOnboardingCompleted', options


  updateStackTemplate: ->

    selectedProvider  = @providerSelectionView.selected?.getOption 'provider'

    if selectedProvider is 'vagrant'
      @stackTemplate = @getDefaultStackTemplate selectedProvider, 'json'
      return

    codeSetupPanes    = @codeSetupView.tabView.panes
    serverConfigPanes = @configurationView.tabView.panes
    selectedInstances = {}

    serverConfigPanes.forEach (pane, index) ->

      selectedServices = []
      { configView, instanceTypeSelectBox } = pane
      { configurationToggles } = configView

      serverConfig    = selectedInstances["example_#{++index}"] =
        instance_type : instanceTypeSelectBox.getValue()
        ami           : ''
        tags          :
          Name        : '${var.koding_user_username}-${var.koding_group_slug}'

      configurationToggles.forEach (toggle) ->
        selectedServices.push (toggle.getOption 'package' or toggle.getOption 'name')  if toggle.getValue()

      if selectedServices.length
        serverConfig.user_data = "export DEBIAN_FRONTEND=noninteractive\napt-get update -y\napt-get -y install #{selectedServices.join ' '}"

    stackTemplate    =
      provider       : PROVIDER_TEMPLATES[selectedProvider]
      resource       :
        aws_instance : selectedInstances

    codeSetupPanes.forEach (pane, index) ->
      selectedService = pane.view.selected?.getOption 'service'
      cloneText       = CLONE_REPO_TEMPLATES[selectedService]
      serverConfig    = stackTemplate.resource.aws_instance["example_#{++index}"]
      groupSlug       = kd.singletons.groupsController.getCurrentGroup().slug
      user_data       = serverConfig?.user_data

      if cloneText

        cloneText = cloneText.replace 'your-organization', groupSlug

        if serverConfig
          if user_data
            serverConfig.user_data = """
              #{user_data}
              #{cloneText}
            """
          else
            serverConfig.user_data = cloneText  if serverConfig


    { content, err } = jsonToYaml stackTemplate

    if err
      return new kd.NotificationView 'Unable to update stack template preview'

    @stackTemplate = JSON.stringify stackTemplate


  getDefaultStackTemplate: (provider, format = 'json') ->

    stackTemplates          =
      vagrant               :
        resource            :
          vagrant_instance  :
            localvm         :
              cpus          : 2
              memory        : 2048
              box           : 'ubuntu/trusty64'
              user_data     : '''
                sudo apt-get install sl -y
                touch /tmp/${var.koding_user_username}.txt
              '''

    stackTemplate = stackTemplates[provider] ? { error: 'Provider not supported' }

    if format is 'yaml'
      { content, err } = jsonToYaml stackTemplate
      return content
    else
      return JSON.stringify stackTemplate


  onboardingCompleted: ->

    @hide()

    selectedProvider = @providerSelectionView.selected?.getOption 'provider'
    @emit 'StackOnboardingCompleted', {
      selectedProvider, template: { content: @stackTemplate }
    }


  pistachio: ->

    return '''
      {{> @getStartedView}}
      {{> @providerSelectionView}}
      {{> @configurationView}}
      {{> @codeSetupView}}
      <footer>
        {{> @backButton}}
        {{> @nextButton}}
        {{> @skipLink}}
        {{> @cancelButton}}
      </footer>
    '''
