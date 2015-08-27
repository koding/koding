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

    tabLength = @tabView.handles.length

    if tabLength is 2
      return new kd.NotificationView
        title    : 'This is a preview mode. You can add more server manually in next steps.'
        duration : 3663

    name = "Server #{tabLength + 1}"

    @tabView.addPane pane = new kd.TabPaneView { name, closable }

    pane.addSubView pane.configView = configView = new ServerConfigurationView
    @tabHandleContainer.repositionPlusHandle @tabView.handles

    pane.tabHandle.addSubView pane.instanceTypeSelectBox = new kd.SelectBox
      defaultValue  : 't2.micro'
      selectOptions : [
        { title: 't2.micro',  value: 't2.micro'  }
        { title: 't2.small',  value: 't2.small'  }
        { title: 't2.medium', value: 't2.medium' }
      ]
      callback: => @emit 'UpdateStackTemplate', yes

    configView.on 'UpdateStackTemplate', =>
      @emit 'UpdateStackTemplate'

    @tabView.on 'PaneRemoved', =>
      @emit 'UpdateStackTemplate'

    @emit 'UpdateStackTemplate', yes


  pistachio: ->

    return """
      <div class="header">
        <p class="title">What do you want installed?</p>
        <p class="description">You can configure your services or install new ones.</p>
      </div>
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """
