kd      = require 'kd'
JView   = require 'app/jview'
globals = require 'globals'
Tracker = require 'app/util/tracker'
checkFlag = require 'app/util/checkFlag'


module.exports = class ProviderSelectionView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry options.cssClass, 'provider-selection'

    super options, data

    @createProviders()

  createProviders: ->

    providers        = [
      'aws', 'vagrant', 'google', 'azure', 'digitalocean', 'rackspace'
    ]
    enabledProviders = ['aws', 'vagrant', 'google']
    betaProviders = ['vagrant', 'google']

    @providers = new kd.CustomHTMLView { cssClass: 'providers box-wrapper clearfix' }

    providers.forEach (provider) =>
      extraClass = 'coming-soon'
      label      = 'Coming Soon'
      beta       = ''
      betaLabel  = ''

      if provider in enabledProviders
        extraClass = ''
        label      = ''

        if provider in betaProviders
          beta       = 'beta'
          betaLabel  = 'BETA'


      @providers.addSubView providerView = new kd.CustomHTMLView
        cssClass : "provider box #{extraClass} #{provider}"
        provider : provider
        partial  : """
          <img class="#{provider}" src="/a/images/providers/stacks/#{provider}.png" />
          <div class="label">#{label}</div>
          <div class="#{beta}">#{betaLabel}</div>
        """
        click: =>
          return if extraClass is 'coming-soon'

          Tracker.track Tracker["STACKS_WIZARD_SELECTED_#{provider.toUpperCase()}"]

          providerView.setClass 'selected'
          @selected?.unsetClass 'selected'
          @selected = if @selected is providerView then null else providerView
          @emit 'UpdateStackTemplate', @selected
          @emit 'HiliteTemplate', 'all'


  pistachio: ->

    '''
    <header>
      <h1>Select a Provider</h1>
    </header>
    <main>
      {{> @providers}}
    </main>
    '''
