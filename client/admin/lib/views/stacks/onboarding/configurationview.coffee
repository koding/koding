kd    = require 'kd'
JView = require 'app/jview'
ApplicationTabHandleHolder = require 'app/commonviews/applicationview/applicationtabhandleholder'
ServerConfigurationView = require './serverconfigurationview'


module.exports = class ConfigurationView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-onboarding configuration'

    super options, data

    @createTabView()
    @createFooter()


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

    pane.addSubView new ServerConfigurationView
    @tabHandleContainer.repositionPlusHandle @tabView.handles


  createFooter: ->

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
        <p class="title">What do you want installed?</p>
        <p class="description">You can configure your services or install new ones.</p>
      </div>
      {{> @tabHandleContainer}}
      {{> @tabView}}
      <div class="footer">
        {{> @backButton}}
        {{> @nextButton}}
        {{> @skipLink}}
      </div>
    """

