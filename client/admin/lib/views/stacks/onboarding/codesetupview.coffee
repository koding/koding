kd                         = require 'kd'
JView                      = require 'app/jview'
ApplicationTabHandleHolder = require 'app/commonviews/applicationview/applicationtabhandleholder'


module.exports = class CodeSetupView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry options.cssClass, 'code-setup configuration'

    super options, data

    @tabHandleContainer   = new ApplicationTabHandleHolder
      delegate            : this
      addPlusHandle       : no
      addCloseHandle      : no
      addFullscreenHandle : no

    @tabView = new kd.TabView
      enableMoveTabHandle : no
      tabHandleContainer  : @tabHandleContainer

    @addPane()


  addPane: ->

    name     = "Server #{@tabView.handles.length + 1}"
    closable = no

    @tabView.addPane pane = new kd.TabPaneView { name, closable }

    pane.addSubView pane.view = @createServicesView()
    @tabHandleContainer.repositionPlusHandle @tabView.handles


  createServicesView: ->

    services = [ 'github', 'bitbucket', 'gitlab', 'owngitserver' ]

    servicesView = new kd.CustomHTMLView cssClass: 'services box-wrapper'

    services.forEach (service) =>
      extraClass = 'coming-soon'
      label      = 'Coming Soon'

      if service in [ 'github', 'owngitserver' ]
        extraClass = ''
        label      = if service is 'owngitserver' then 'Your Git server' else ''

      servicesView.addSubView serviceView = new kd.CustomHTMLView
        cssClass: "service box #{extraClass} #{service}"
        service : service
        partial : """
          <img class="#{service}" src="/a/images/providers/stacks/#{service}.png" />
          <div class="label">#{label}</div>
        """
        click: =>
          return  if extraClass is 'coming-soon'

          serviceView.setClass  'selected'
          @selected?.unsetClass 'selected'
          @selected = if @selected is serviceView then null else serviceView
          @emit 'UpdateStackTemplate'

    return servicesView


  pistachio: ->

    return """
      <div class="header">
        <p class="title">Where is your code?</p>
        <p class="description">Koding can pull your project’s codebase from wherever its hosted.</p>
      </div>
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """
