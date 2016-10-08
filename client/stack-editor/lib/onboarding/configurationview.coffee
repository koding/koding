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

    @tabView.unsetClass 'kdscrollview'

    @on 'PlusHandleClicked', @bound 'addPane'

    @addPane no


  addPane: (closable = yes) ->

    tabLength = @tabView.handles.length

    if tabLength is 2
      return new kd.NotificationView
        title    : 'This is a preview mode. You can add more servers manually in the next steps.'
        duration : 3663

    name = "Server #{tabLength + 1}"

    @tabView.addPane pane = new kd.TabPaneView { name, closable }

    pane.addSubView pane.configView = configView = new ServerConfigurationView
    @tabHandleContainer.repositionPlusHandle @tabView.handles

    pane.tabHandle.addSubView pane.instanceTypeSelectBox = select = new kd.SelectBox
      defaultValue  : 't2.nano'
      selectOptions : [
        { title: 't2.nano',   value: 't2.nano' }
        { title: 't2.micro',  value: 't2.micro' }
        { title: 't2.small',  value: 't2.small' }
        { title: 't2.medium', value: 't2.medium' }
      ]
      callback: =>
        @emit 'StackDataChanged', yes
        @emit 'InstanceTypeChanged', select.getValue()

    @tabView.on 'PaneRemoved', => @emit 'StackDataChanged'

    configView.on 'StackDataChanged', => @emit 'StackDataChanged'
    configView.on 'HiliteTemplate', (type, selector) => @emit 'HiliteTemplate', type, selector

    @emit 'StackDataChanged', yes
    @emit 'HiliteTemplate', 'block', 'example_2'  if closable


  pistachio: ->

    '''
    <header>
      <h1>What do you want installed?</h1>
    </header>
    <main>
      {{> @tabHandleContainer}}
      {{> @tabView}}
    </main>
    '''
