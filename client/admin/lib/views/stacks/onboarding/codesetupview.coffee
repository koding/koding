kd    = require 'kd'
JView = require 'app/jview'


module.exports = class CodeSetupView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-onboarding code-setup'

    super options, data

    @createServices()


  createServices: ->

    services = [ 'github', 'bitbucket', 'gitlab', 'owngitserver' ]

    @services = new kd.CustomHTMLView cssClass: 'services box-wrapper'

    services.forEach (service) =>
      extraClass = 'coming-soon'
      label      = 'Coming Soon'

      if service in [ 'github', 'owngitserver' ]
        extraClass = if service is 'github' then 'selected' else ''
        label      = if service is 'owngitserver' then 'Your Git server' else ''

      @services.addSubView new kd.CustomHTMLView
        cssClass: "service box #{extraClass} #{service}"
        partial : """
          <img class="#{service}" src="/a/images/providers/stacks/#{service}.png" />
          <div class="label">#{label}</div>
        """

      @backButton = new kd.ButtonView
        cssClass  : 'solid outline medium back'
        title     : 'Back'

      @nextButton = new kd.ButtonView
        cssClass  : 'solid green medium next'
        title     : 'Next'

      @skipLink   = new kd.CustomHTMLView
        cssClass  : 'skip-setup'
        partial   : 'Skip setup guide'


  pistachio: ->

    return """
      <div class="header">
        <p class="title">Where is your code?</p>
        <p class="description">Koding can pull your project’s codebase from wherever its hosted.</p>
      </div>
      {{> @services}}
      <div class="footer">
        {{> @backButton}}
        {{> @nextButton}}
        {{> @skipLink}}
      </div>
    """
