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
        <p class="title">Configure your teams new development environment...</p>
        <p class="description">Select the number of servers, their type and what
          is installed by default on each. The list of software items below is
          not an exhaustive list, it’s simply to show you what’s possible.<br/>
          In the final step you will be able to edit the Stack file to include
          any additional software, language or framework.
        </p>
      </div>
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """
