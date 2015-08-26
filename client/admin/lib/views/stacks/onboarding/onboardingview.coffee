kd                    = require 'kd'
JView                 = require 'app/jview'
CodeSetupView         = require './codesetupview'
{ jsonToYaml }        = require '../yamlutils'
applyMarkdown         = require 'app/util/applyMarkdown'
GetStartedView        = require './getstartedview'
ConfigurationView     = require './configurationview'
ProviderSelectionView = require './providerselectionview'
CLONE_REPO_TEMPLATES  =
  github              : 'git clone git@github.com/username/reponame.git'
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
      page.on 'StackTemplateNeedsToBeUpdated', =>
        @stackPreview.show()
        @updateStackTemplate()

    @on 'PageNavigationRequested', (direction) =>
      pageIndex  = @pages.indexOf @currentPage
      nextIndex  = if direction is 'next' then ++pageIndex else --pageIndex
      targetPage = @pages[nextIndex]

      if targetPage
        @currentPage.hide()
        targetPage.show()
        @setClass 'get-started'  if targetPage is @getStartedView
        @currentPage = targetPage
      else
        @hide()
        @emit 'StackOnboardingCompleted', { template: content: @stackTemplate }


    @getStartedView.on 'NextPageRequested', =>
      @unsetClass 'get-started'
      @emit 'PageNavigationRequested', 'next'


    @getStartedView.emit 'NextPageRequested'  if @getOption 'skipOnboarding'

    @providerSelectionView.on 'StackTemplateNeedsToBeUpdated', (isSelected) =>
      if isSelected
        @nextButton.enable()
        @stackPreview.show()
      else
        @nextButton.disable()
        @stackPreview.hide()


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

    selectedProvider    = @providerSelectionView.selected?.getOption 'provider'
    selectedCodeService = @codeSetupView.selected?.getOption 'service'
    serverConfigPanes   = @configurationView.tabView.panes
    selectedInstances   = {}

    serverConfigPanes.forEach (pane, index) ->

      selectedServices = []
      { configView, instanceTypeSelectBox } = pane
      { configurationToggles } = configView

      serverConfig = selectedInstances["example_#{++index}"] =
        instance_type: instanceTypeSelectBox.getValue()
        ami: ''

      configurationToggles.forEach (toggle) ->
        selectedServices.push toggle.getOption 'name'  if toggle.getValue()

      if selectedServices.length
        serverConfig.user_data = "apt-get -y install #{selectedServices.join ' '}"

    stackTemplate    =
      provider       : PROVIDER_TEMPLATES[selectedProvider]
      resource       :
        aws_instance : selectedInstances

    if selectedCodeService
      cloneText = CLONE_REPO_TEMPLATES[selectedCodeService]

      for serverName, serverConfig of stackTemplate.resources.aws_instance
        { user_data } = serverConfig

        if user_data
          serverConfig.user_data = """
            #{user_data}
            #{cloneText}
          """
        else
          serverConfig.user_data = cloneText


    { content, err } = jsonToYaml JSON.stringify stackTemplate

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
