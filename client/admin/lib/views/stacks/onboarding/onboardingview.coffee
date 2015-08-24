kd                    = require 'kd'
JView                 = require 'app/jview'
CodeSetupView         = require './codesetupview'
{ jsonToYaml }        = require '../yamlutils'
applyMarkdown         = require 'app/util/applyMarkdown'
GetStartedView        = require './getstartedview'
ConfigurationView     = require './configurationview'
ProviderSelectionView = require './providerselectionview'


module.exports = class OnboardingView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-onboarding main-content'

    super options, data

    @createViews()
    @createFooter()
    @createStackPreview()

    @pages = [ @getStartedView, @providerSelectionView, @configurationView, @codeSetupView ]

    @bindPageEvents()


  createViews: ->

    @getStartedView        = new GetStartedView
    @codeSetupView         = new CodeSetupView          cssClass: 'hidden'
    @configurationView     = new ConfigurationView      cssClass: 'hidden'
    @providerSelectionView = new ProviderSelectionView  cssClass: 'hidden'

    @setClass 'get-started'
    @currentPage = @getStartedView


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
        @emit 'StackOnboardingCompleted'


    @getStartedView.on 'NextPageRequested', =>
      @unsetClass 'get-started'
      @emit 'PageNavigationRequested', 'next'


    @getStartedView.emit 'NextPageRequested'


  createFooter: ->

    @backButton = new kd.ButtonView
      cssClass  : 'solid outline medium back'
      title     : 'Back'
      callback  : => @emit 'PageNavigationRequested', 'prev'

    @nextButton = new kd.ButtonView
      cssClass  : 'solid green medium next'
      title     : 'Next'
      callback  : =>
        @validatePageInteraction =>
          @emit 'PageNavigationRequested', 'next'

    @skipLink   = new kd.CustomHTMLView
      cssClass  : 'skip-setup'
      partial   : 'Skip setup guide'


  validatePageInteraction: (callback) ->

    isCompleted = yes

    switch @currentPage
      when @providerSelectionView
        unless @providerSelectionView.selected
          new kd.NotificationView title: 'Please select a provider'
          isCompleted = no

    callback()  if isCompleted


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
    cloneRepoTemplates  =
      github            : 'git clone git@github.com/username/reponame.git'
      owngitserver      : 'git clone git@yourgitserver.com/reponame.git'
    providerTemplates   =
      aws               :
        'access_key'    : '${var.aws_access_key}'
        'secret_key'    : '${var.aws_secret_key}'


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
      provider       : providerTemplates[selectedProvider]
      resources      :
        aws_instance : selectedInstances

    if selectedCodeService
      cloneText = cloneRepoTemplates[selectedCodeService]

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
