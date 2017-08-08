kd = require 'kd'
globals = require 'globals'


Tracker = require 'app/util/tracker'

Events = require '../../events'


module.exports = class ProviderSelectionView extends kd.View

  constructor: (options = {}, data) ->

    options.cssClass ?= 'provider-selection'

    super options, data

    @createProviders()


  createProviders: ->

    { providers } = globals.config

    supportedProviders = (Object.keys providers).filter (p) ->
      return p  if providers[p].supported

    @providers = new kd.CustomHTMLView
      cssClass: 'providers box-wrapper clearfix'

    supportedProviders.forEach (provider) =>

      _provider = providers[provider]

      if not _provider.enabled
        extraClass = 'coming-soon'
        stateLabel = 'Coming soon'
      else if _provider.enabled is 'beta'
        extraClass = 'beta'
        stateLabel = 'BETA'
      else
        extraClass = ''
        stateLabel = ''

      @providers.addSubView providerView = new kd.CustomHTMLView
        cssClass   : "provider box #{provider} #{extraClass}"
        provider   : provider
        attributes : { 'data-before-content': stateLabel }
        click      : =>
          return  if extraClass is 'coming-soon'

          Tracker.track Tracker["STACKS_WIZARD_SELECTED_#{provider.toUpperCase()}"]

          providerView.setClass 'selected'
          @selected?.unsetClass 'selected'

          @selected = if @selected is providerView then null else providerView
          @emit Events.SelectedProviderChanged, @selected


  pistachio: ->

    '''
    <header>
      <h1>Select a Provider</h1>
    </header>
    <main>
      {{> @providers}}
    </main>
    '''
