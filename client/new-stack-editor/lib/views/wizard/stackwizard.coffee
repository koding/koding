kd = require 'kd'
JView = require 'app/jview'

ProviderSelectionView = require './providerselectionview'


module.exports = class StackWizard extends JView

  constructor: (options = {}, data) ->


    options.cssClass = 'stack-wizard'

    super options, data

    @providerSelectionView = new ProviderSelectionView

    @providerSelectionView.on 'SelectedProviderChanged', (isSelected) =>
      if isSelected
      then @createButton.enable()
      else @createButton.disable()

    @cancelButton = new kd.ButtonView
      cssClass : 'cancel'
      title    : 'CANCEL'
      callback : => @emit 'StackWizardCancelled'

    @createButton = new kd.ButtonView
      cssClass  : 'outline next'
      title     : 'Create Stack'
      disabled  : yes
      callback  : @bound 'providerSelected'


  providerSelected: ->

    kd.utils.defer @bound 'destroy'

    selectedProvider = @providerSelectionView.selected?.getOption 'provider'
    @emit 'ProviderSelected', selectedProvider


  pistachio: ->

    '''
      {{> @providerSelectionView}}
      <footer>
        {{> @createButton}}
        {{> @cancelButton}}
      </footer>
    '''
