kd                  = require 'kd'
CustomLinkView      = require 'app/customlinkview'
IDEChatSettingsPane = require './idechatsettingspane'
envDataProvider     = require 'app/userenvironmentdataprovider'

# refactor notes:
# no need for a KDTabView here but
# didnot invest more for the timebeing - SY
module.exports = class IDEChatView extends kd.TabView

  constructor: (options = {}, data)->

    options.cssClass            = 'chat-view loading onboarding'
    options.hideHandleContainer = yes

    super options, data

    @visible = no

    { @rtm, @isInSession, @mountedMachineUId } = options

    @unsetClass 'kdscrollview'

    @addSubView new CustomLinkView
      title    : ''
      cssClass : 'close'
      tooltip  :
        title  : 'Minimize'
      icon     : {}
      click    : (event) =>
        kd.utils.stopDOMEvent event
        @end()

    @createLoader()

    kd.singletons.appManager.require 'Activity', @bound 'createPanes'

    @once 'CollaborationStarted',        @bound 'removeLoader'
    @once 'CollaborationNotInitialized', @bound 'removeLoader'
    @once 'CollaborationEnded',          @bound 'destroy'


  end: -> @hide()


  createLoader: ->

    @loaderView = new kd.View cssClass: 'loader-view'

    @loaderView.addSubView new kd.LoaderView
      showLoader : yes
      size       :
        width    : 24

    @loaderView.addSubView new kd.CustomHTMLView
      cssClass : 'label'
      partial  : 'Preparing collaboration'

    @addSubView @loaderView


  removeLoader: ->

    @loaderView.destroy()
    @unsetClass 'loading'


  createPanes: ->

    channel         = @getData()
    settingsOptions = { @rtm, @isInSession }

    @addPane @settingsPane = new IDEChatSettingsPane settingsOptions, channel

    @settingsPane.forwardEvents this, [
      'CollaborationNotInitialized'
      'CollaborationStarted'
      'CollaborationEnded'
      'ParticipantJoined'
      'ParticipantLeft'
    ]

    @settingsPane.on 'SessionStarted', @bound 'hide'

    @emit 'ready'


  getIDEApp : -> envDataProvider.getIDEFromUId @mountedMachineUId

  showSettingsPane: -> @showPane @settingsPane
