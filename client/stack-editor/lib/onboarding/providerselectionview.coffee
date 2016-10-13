kd = require 'kd'
JView = require 'app/jview'
globals = require 'globals'
Tracker = require 'app/util/tracker'
checkFlag = require 'app/util/checkFlag'


module.exports = class ProviderSelectionView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry options.cssClass, 'provider-selection'

    super options, data

    @createProviders()


  createProviders: ->

    { providers } = globals.config

    supportedProviders = (Object.keys providers).filter (p) ->
      return p  if providers[p].supported

    @providers = new kd.CustomHTMLView
      cssClass: 'providers box-wrapper clearfix'

    supportedProviders.forEach (provider) =>

      _provider  = providers[provider]
      extraClass = 'coming-soon'

      if _provider.enabled
        extraClass = if _provider.enabled is 'beta'
        then 'beta'
        else ''

      @providers.addSubView providerView = new kd.CustomHTMLView
        cssClass : "provider box #{provider} #{extraClass}"
        provider : provider
        click    : =>
          return  if extraClass is 'coming-soon'

          Tracker.track Tracker["STACKS_WIZARD_SELECTED_#{provider.toUpperCase()}"]

          providerView.setClass 'selected'
          @selected?.unsetClass 'selected'

          @selected = if @selected is providerView then null else providerView
          @emit 'SelectedProviderChanged', @selected


  pistachio: ->

    '''
    <header>
      <h1>Select a Provider</h1>
    </header>
    <main>
      {{> @providers}}
    </main>
    '''
