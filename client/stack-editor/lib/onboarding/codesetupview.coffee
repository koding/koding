kd                         = require 'kd'
JView                      = require 'app/jview'
ApplicationTabHandleHolder = require 'app/commonviews/applicationview/applicationtabhandleholder'
Tracker                    = require 'app/util/tracker'


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

    pane.tabHandle.addSubView pane.instanceTypeLabel = new kd.CustomHTMLView
      tagName  : 'span'
      cssClass : 'title'
      partial  : 't2.nano'

    @tabView.showPaneByIndex 0


  createServicesView: ->

    services = [ 'github', 'bitbucket', 'gitlab', 'yourgitserver' ]
    servicesView = new kd.CustomHTMLView { cssClass: 'services box-wrapper' }

    services.forEach (service) =>
      label = if service is 'yourgitserver' then 'Your Git server' else ''

      servicesView.addSubView serviceView = new kd.CustomHTMLView
        cssClass: "service box #{service}"
        service : service
        partial : """
          <img class="#{service}" src="/a/images/providers/stacks/#{service}.png" />
          <div class="label">#{label}</div>
        """
        click: =>

          Tracker.track Tracker["STACKS_WIZARD_SELECTED_#{service.toUpperCase()}"]

          serviceView.setClass  'selected'
          servicesView.selected?.unsetClass 'selected'
          servicesView.selected = if servicesView.selected is serviceView then null else serviceView
          @emit 'StackDataChanged'
          @emit 'HiliteTemplate', 'line', service

    return servicesView


  pistachio: ->

    '''
    <header>
      <h1>Where is your code?</h1>
    </header>
    <main>
      {{> @tabHandleContainer}}
      {{> @tabView}}
    </main>
    '''
