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
    @createStackPreview()


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


  createStackPreview: ->

    @preview    = new kd.CustomHTMLView
      cssClass : 'stack-preview'
      partial  : """
        <div class="header">STACK FILE PREVIEW</div>
      """

    @preview.addSubView new kd.CustomHTMLView
      partial : """
        <div class="lines">
          <div>1</div>
          <div>2</div>
          <div>3</div>
          <div>4</div>
        </div>
        <div class="code">
          <p>provider:</p>
          <p>aws:</p>
          <p>access_key: '${var.access_key}'</p>
          <p>secret_key: '${var.secret_key}'</p>
        </div>
      """


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
      {{> @preview}}
    """
