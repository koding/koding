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


  createFooter: ->

    @backButton = new kd.ButtonView
      cssClass  : 'solid outline medium back'
      title     : 'Back'
      callback  : => @emit 'PageNavigationRequested', 'prev'

    @nextButton = new kd.ButtonView
      cssClass  : 'solid green medium next'
      title     : 'Next'
      callback  : => @emit 'PageNavigationRequested', 'next'

    @skipLink   = new kd.CustomHTMLView
      cssClass  : 'skip-setup'
      partial   : 'Skip setup guide'


  createStackPreview: ->

    @preview    = new kd.CustomHTMLView
      cssClass : 'stack-preview'
      partial  : """
        <div class="header">STACK FILE PREVIEW</div>
      """

    @preview.addSubView new kd.CustomHTMLView
      partial : """
        <div class="lines">
          <div>1</div>
          <div>2</div>
          <div>3</div>
          <div>4</div>
        </div>
        <div class="code">
          <p>provider:</p>
          <p>aws:</p>
          <p>access_key: '${var.access_key}'</p>
          <p>secret_key: '${var.secret_key}'</p>
        </div>
      """


  pistachio: ->

    return """
      <div class="footer">
        {{> @backButton}}
        {{> @nextButton}}
        {{> @skipLink}}
      </div>
      {{> @preview}}
    """
