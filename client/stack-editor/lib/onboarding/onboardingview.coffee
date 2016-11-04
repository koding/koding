kd                    = require 'kd'
JView                 = require 'app/jview'
Tracker               = require 'app/util/tracker'
CustomLinkView        = require 'app/customlinkview'
{ jsonToYaml }        = require 'app/util/stacks/yamlutils'

ProviderSelectionView = require './providerselectionview'


module.exports = class OnboardingView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-onboarding main-content'

    super options, data

    @providerSelectionView = new ProviderSelectionView

    @providerSelectionView.on 'SelectedProviderChanged', (isSelected) =>
      if isSelected
      then @createButton.enable()
      else @createButton.disable()

    @cancelButton = new kd.ButtonView
      cssClass : 'StackEditor-OnboardingModal--cancel'
      title    : 'CANCEL'
      callback : @bound 'destroy'

    @createButton = new kd.ButtonView
      cssClass  : 'outline next'
      title     : 'Create Stack'
      disabled  : yes
      callback  : @bound 'onboardingCompleted'


  onboardingCompleted: ->

    kd.utils.defer @bound 'destroy'

    selectedProvider = @providerSelectionView.selected?.getOption 'provider'
    @emit 'StackOnboardingCompleted', selectedProvider


  pistachio: ->

    '''
      {{> @providerSelectionView}}
      <footer>
        {{> @createButton}}
        {{> @cancelButton}}
      </footer>
    '''
