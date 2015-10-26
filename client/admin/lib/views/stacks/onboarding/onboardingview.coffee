$                     = require 'jquery'
kd                    = require 'kd'
hljs                  = require 'highlight.js'
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

      page.on 'HiliteTemplate', (type, keyword) =>
        kd.utils.wait 737, => @hiliteTemplate type, keyword

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

    @configurationView.on 'InstanceTypeChanged', (type) =>
      for pane, index in @configurationView.tabView.panes
        label = @codeSetupView.tabView.panes[index]?.instanceTypeLabel
        label.updatePartial pane.instanceTypeSelectBox.getValue()  if label

        @hiliteTemplate 'line', type


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

    @createStackPreviewFromYaml content
    @stackTemplate = JSON.stringify stackTemplate


  createStackPreviewFromYaml: (content) ->

    linesMarkup   = ''
    codeMarkup    = ''
    templateLines = content.split '\n'

    @stackContent.destroySubViews()
    @stackPreviewLines = []

    for line, index in templateLines when line
      line = new kd.CustomHTMLView
        cssClass : 'line'
        partial  : """
          <div class="number">#{++index}</div>
          <pre><code class="coffee">#{line}</code></pre>
        """

      @stackContent.addSubView line
      @stackPreviewLines.push line

    hljs.highlightBlock line  for line in document.querySelectorAll '.line code'


  hiliteTemplate: (type, keyword) ->

    commonSelector = $ ".stack-preview .line:contains('#{keyword}')"

    if type is 'all'
      lines = document.querySelectorAll '.stack-preview .line'
      line.classList.add 'hilite'  for line in lines

    else if type is 'line'
      if tabView = @currentPage.tabView
        if tabView.getActivePaneIndex() is 1
          commonSelector.last().addClass 'hilite'
        else
          commonSelector.first().addClass 'hilite'
      else
        commonSelector.addClass 'hilite'

    else if type is 'block'
      commonSelector.prev().nextAll().addClass 'hilite'

    @showStackTemplateTooltip type, keyword


  showStackTemplateTooltip: (type, keyword) ->

    return  unless type

    messages =
      all    : 'This is the initial stack template to build your AWS instances.'
      block  : 'This is the lines to add another machine to your stack.'
      line   : ->
        if keyword in [ 'github', 'gitlab', 'yourgitserver', 'bitbucket' ]
          return 'You can clone any git repository to your machines when the stack is built.'
        else
          return 'You can install any package to machines when stack is built.'

    elements =
      all    : @stackPreviewLines.first
      line   : =>
        for line in @stackPreviewLines
          if line.getElement().innerHTML.indexOf(keyword) > -1
            return line

    elements.block = elements.line

    el = elements[type]?() or elements[type]
    el.setTooltip
      title    : messages[type]?() or messages[type]
      cssClass : 'stack-tooltip'

    el.tooltip.show()

    @parent.once 'scroll', -> el.tooltip?.hide()


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
