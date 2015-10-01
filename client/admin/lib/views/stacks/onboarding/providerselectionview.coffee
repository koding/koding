kd    = require 'kd'
JView = require 'app/jview'


module.exports = class ProviderSelectionView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry options.cssClass, 'provider-selection'

    super options, data

    @createProviders()


  createProviders: ->

    providers = [ 'aws', 'koding', 'azure', 'digitalocean', 'googlecloud', 'rackspace' ]

    @providers = new kd.CustomHTMLView cssClass: 'providers box-wrapper'

    providers.forEach (provider) =>
      extraClass = 'coming-soon'
      label      = 'Coming Soon'

      if provider is 'aws'
        extraClass = ''
        label      = ''

      @providers.addSubView providerView = new kd.CustomHTMLView
        cssClass : "provider box #{extraClass} #{provider}"
        provider : provider
        partial  : """
          <img class="#{provider}" src="/a/images/providers/stacks/#{provider}.png" />
          <div class="label">#{label}</div>
        """
        click: =>
          return if extraClass is 'coming-soon'

          providerView.setClass 'selected'
          @selected?.unsetClass 'selected'
          @selected = if @selected is providerView then null else providerView
          @emit 'UpdateStackTemplate', @selected
          @emit 'HiliteTemplate', 'all'


  pistachio: ->

    return """
      <div class="header">
        <p class="title">What provider do you want to use?</p>
        <p class="description">Koding machines run on your own cloud infrastructure. You can switch providers later at any time.</p>
      </div>
      {{> @providers}}
    """
