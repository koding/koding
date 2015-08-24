kd    = require 'kd'
JView = require 'app/jview'

ServerConfigurationView    = require './serverconfigurationview'
ApplicationTabHandleHolder = require 'app/commonviews/applicationview/applicationtabhandleholder'


module.exports = class ConfigurationView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry options.cssClass, 'configuration'

    super options, data

    @createTabView()


  createTabView: ->

    @tabHandleContainer   = new ApplicationTabHandleHolder
      delegate            : this
      addCloseHandle      : no
      addFullscreenHandle : no

    @tabView = new kd.TabView
      enableMoveTabHandle : no
      tabHandleContainer  : @tabHandleContainer

    @on 'PlusHandleClicked', @bound 'addPane'

    @addPane no


  addPane: (closable = yes) ->

    name = "Server #{@tabView.handles.length + 1}"

    @tabView.addPane pane = new kd.TabPaneView { name, closable }

    pane.addSubView pane.configView = configView = new ServerConfigurationView
    @tabHandleContainer.repositionPlusHandle @tabView.handles

    configView.on 'StackTemplateNeedsToBeUpdated', =>
      @emit 'StackTemplateNeedsToBeUpdated'

    @tabView.on 'PaneRemoved', =>
      @emit 'StackTemplateNeedsToBeUpdated'

    @emit 'StackTemplateNeedsToBeUpdated'


  pistachio: ->

    return """
      <div class="header">
        <p class="title">What do you want installed?</p>
        <p class="description">You can configure your services or install new ones.</p>
      </div>
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """
