kd = require 'kd'


Events = require '../../events'
ProviderSelectionView = require './providerselectionview'


module.exports = class StackWizard extends kd.View

  constructor: (options = {}, data) ->


    options.cssClass = 'stack-wizard'

    super options, data

    @providerSelectionView = new ProviderSelectionView

    @providerSelectionView.on Events.SelectedProviderChanged, (isSelected) =>
      if isSelected
      then @createButton.enable()
      else @createButton.disable()

    @cancelButton = new kd.ButtonView
      cssClass : 'cancel'
      title    : 'CANCEL'
      callback : => @emit Events.StackWizardCancelled

    @createButton = new kd.ButtonView
      cssClass  : 'outline next'
      title     : 'Create Stack'
      disabled  : yes
      callback  : @bound 'providerSelected'


  providerSelected: ->

    kd.utils.defer @bound 'destroy'

    selectedProvider = @providerSelectionView.selected?.getOption 'provider'
    @emit Events.ProviderSelected, selectedProvider


  pistachio: ->

    '''
    {{> @providerSelectionView}}
    <footer>
      {{> @createButton}}
      {{> @cancelButton}}
    </footer>
    '''
