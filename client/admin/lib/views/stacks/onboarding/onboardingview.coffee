kd                    = require 'kd'
JView                 = require 'app/jview'
CodeSetupView         = require './codesetupview'
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


  updateStackTemplate: ->

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
