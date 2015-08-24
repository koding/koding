kd    = require 'kd'
JView = require 'app/jview'


module.exports = class CodeSetupView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry options.cssClass, 'code-setup'

    super options, data

    @createServices()


  createServices: ->

    services = [ 'github', 'bitbucket', 'gitlab', 'owngitserver' ]

    @services = new kd.CustomHTMLView cssClass: 'services box-wrapper'

    services.forEach (service) =>
      extraClass = 'coming-soon'
      label      = 'Coming Soon'

      if service in [ 'github', 'owngitserver' ]
        extraClass = ''
        label      = if service is 'owngitserver' then 'Your Git server' else ''

      @services.addSubView serviceView = new kd.CustomHTMLView
        cssClass: "service box #{extraClass} #{service}"
        service : service
        partial : """
          <img class="#{service}" src="/a/images/providers/stacks/#{service}.png" />
          <div class="label">#{label}</div>
        """
        click: =>
          return if extraClass is 'coming-soon'

          serviceView.setClass  'selected'
          @selected?.unsetClass 'selected'
          @selected = if @selected is serviceView then null else serviceView



  pistachio: ->

    return """
      <div class="header">
        <p class="title">Where is your code?</p>
        <p class="description">Koding can pull your project’s codebase from wherever its hosted.</p>
      </div>
      {{> @services}}
    """
