kd                    = require 'kd'
JView                 = require 'app/jview'
CodeSetupView         = require './codesetupview'
{ jsonToYaml }        = require '../yamlutils'
applyMarkdown         = require 'app/util/applyMarkdown'
GetStartedView        = require './getstartedview'
ConfigurationView     = require './configurationview'
ProviderSelectionView = require './providerselectionview'
CLONE_REPO_TEMPLATES  =
  github              : 'git clone git@github.com/your-organization/reponame.git'
  bitbucket           : 'git clone git@bitbucket.org/your-organization/reponame.git'
  gitlab              : 'git clone git@gitlab.com/your-organization/reponame.git'
  owngitserver        : 'git clone git@yourgitserver.com/reponame.git'
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
    @createStackPreview()

    @bindPageEvents()


  createViews: ->

    @getStartedView        = new GetStartedView
    @codeSetupView         = new CodeSetupView          cssClass: 'hidden'
    @configurationView     = new ConfigurationView      cssClass: 'hidden'
    @providerSelectionView = new ProviderSelectionView  cssClass: 'hidden'

    @pages       = [ @getStartedView, @providerSelectionView, @configurationView, @codeSetupView ]
    @currentPage = @getStartedView

    @setClass 'get-started'


  bindPageEvents: ->

    @pages.forEach (page) =>
      page.on 'UpdateStackTemplate', (scrollToBottom) =>
        @stackPreview.show()
        @updateStackTemplate()
        @emit 'ScrollTo', 'bottom'  if scrollToBottom

    @on 'PageNavigationRequested', (direction) =>
      pageIndex  = @pages.indexOf @currentPage
      nextIndex  = if direction is 'next' then ++pageIndex else --pageIndex
      targetPage = @pages[nextIndex]

      if targetPage
        @currentPage.hide()
        targetPage.show()
        @setClass 'get-started'  if targetPage is @getStartedView
        @currentPage = targetPage
        @emit 'ScrollTo', 'top'
      else
        @hide()
        @emit 'StackOnboardingCompleted', { template: content: @stackTemplate }


    @getStartedView.on 'NextPageRequested', =>
      @unsetClass 'get-started'
      @emit 'PageNavigationRequested', 'next'

    @configurationView.once 'UpdateStackTemplate', => @emit 'ScrollTo', 'bottom'
    @codeSetupView.once 'UpdateStackTemplate', => @emit 'ScrollTo', 'bottom'

    @getStartedView.emit 'NextPageRequested'  if @getOption 'skipOnboarding'

    @providerSelectionView.on 'UpdateStackTemplate', (isSelected) =>
      if isSelected
        @nextButton.enable()
        @stackPreview.show()
        @emit 'ScrollTo', 'bottom'
      else
        @nextButton.disable()
        @stackPreview.hide()

    @configurationView.tabView.on 'PaneAdded', => @codeSetupView.addPane()

    @configurationView.tabView.on 'PaneRemoved', =>
      @codeSetupView.tabView.removePane @codeSetupView.tabView.panes.last

    @configurationView.on 'InstanceTypeChanged', =>
      for pane, index in @configurationView.tabView.panes
        label = @codeSetupView.tabView.panes[index]?.instanceTypeLabel
        label.updatePartial pane.instanceTypeSelectBox.getValue()  if label


  createFooter: ->

    @backButton = new kd.ButtonView
      cssClass  : 'solid outline medium back'
      title     : 'Back'
      callback  : => @emit 'PageNavigationRequested', 'prev'

    @nextButton = new kd.ButtonView
      cssClass  : 'solid green medium next'
      title     : 'Next'
      disabled  : yes
      callback  : => @emit 'PageNavigationRequested', 'next'

    @skipLink   = new kd.CustomHTMLView
      cssClass  : 'skip-setup'
      partial   : 'Skip setup guide'
      click     : =>
        @destroy()
        @emit 'StackOnboardingCompleted'


  createStackPreview: ->

    @stackPreview = new kd.CustomHTMLView
      cssClass : 'stack-preview hidden'
      partial  : """
        <div class="header">STACK FILE PREVIEW</div>
      """

    @stackPreview.addSubView @stackContent = new kd.CustomHTMLView
      cssClass: 'has-markdown'


  updateStackTemplate: ->

    selectedProvider  = @providerSelectionView.selected?.getOption 'provider'
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
          Name        : "${var.koding_user_username}-${var.koding_group_slug}"

      configurationToggles.forEach (toggle) ->
        selectedServices.push (toggle.getOption 'package' or toggle.getOption 'name')  if toggle.getValue()

      if selectedServices.length
        serverConfig.user_data = "apt-get -y install #{selectedServices.join ' '}"

    stackTemplate    =
      provider       : PROVIDER_TEMPLATES[selectedProvider]
      resource       :
        aws_instance : selectedInstances

    codeSetupPanes.forEach (pane, index) ->
      selectedService = pane.view.selected?.getOption 'service'
      cloneText       = CLONE_REPO_TEMPLATES[selectedService]
      serverConfig    = stackTemplate.resource.aws_instance["example_#{++index}"]
      groupSlug       = kd.singletons.groupsController.getCurrentGroup().slug
      { user_data }   = serverConfig

      if cloneText

        cloneText = cloneText.replace 'your-organization', groupSlug

        if user_data
          serverConfig.user_data = """
            #{user_data}
            #{cloneText}
          """
        else
          serverConfig.user_data = cloneText


    { content, err } = jsonToYaml stackTemplate

    if err
      return new kd.NotificationView 'Unable to update stack template preview'

    @createStackPreviewFromYaml content
    @stackTemplate = JSON.stringify stackTemplate


  createStackPreviewFromYaml: (content) ->

    linesMarkup   = ''
    codeMarkup    = ''
    templateLines = content.split '\n'

    for index in [1...templateLines.length]
      linesMarkup += "<div>#{index}</div>"

    @stackContent.destroySubViews()
    @stackContent.addSubView new kd.CustomHTMLView
      cssClass : 'lines'
      partial  : "#{linesMarkup}"

    @stackContent.addSubView new kd.CustomHTMLView
      cssClass : 'code'
      partial  : applyMarkdown """
        ```coffee
        #{content}
        ```
      """


  pistachio: ->

    return """
      {{> @getStartedView}}
      {{> @providerSelectionView}}
      {{> @configurationView}}
      {{> @codeSetupView}}
      <div class="footer">
        {{> @backButton}}
        {{> @nextButton}}
        {{> @skipLink}}
      </div>
      {{> @stackPreview}}
    """
