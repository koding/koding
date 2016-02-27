$                    = require 'jquery'
kd                   = require 'kd'
KDButtonViewWithMenu = kd.ButtonViewWithMenu
KDCustomHTMLView     = kd.CustomHTMLView
groupifyLink         = require 'app/util/groupifyLink'
ActivityItemMenuItem = require 'activity/views/activityitemmenuitem'
isMyChannel          = require 'app/util/isMyChannel'
isMyPost             = require 'app/util/isMyPost'
envDataProvider      = require 'app/userenvironmentdataprovider'
isKoding             = require 'app/util/isKoding'

CollaborationChannelParticipantsModel = require 'activity/models/collaborationchannelparticipants'
IDEChatParticipantHeads               = require './idechatparticipantheads'
IDEChatParticipantSearchController    = require './idechatparticipantsearchcontroller'

module.exports = class IDEChatMessagePane extends kd.TabPaneView


  constructor: (options = {}, data)->

    options.cssClass               = 'privatemessage'
    options.type                   = 'privatemessage' # backwards compatibility ~Umut
    options.channelType            = 'collaboration'

    super options, data

    @isInSession = options.isInSession

    isHost = not @isInSession

    @define 'visible', => @getDelegate().visible

    @createHeaderViews()
    @createShareView()


  createHeaderViews: ->

    title        = 'Session'
    channel      = @getData()
    {appManager} = kd.singletons

    header = new KDCustomHTMLView
      tagName  : 'header'
      cssClass : 'general-header'

    { frontApp } = kd.singletons.appManager
    title = if isKoding() then frontApp.workspaceData.name else frontApp.mountedMachine.label

    header.addSubView @title = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'workspace-name'
      partial    : title
      attributes : href : '#'

    header.addSubView @chevron = @createMenu()

    header.addSubView @link = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'session-link'
      partial    : link = groupifyLink "IDE/#{channel.id}", yes
      attributes : href : link

    @addSubView header


  createMenu: ->

    channel = @getData()

    chevron = new KDButtonViewWithMenu
      title          : ''
      cssClass       : 'pm-title-chevron'
      itemChildClass : ActivityItemMenuItem
      delegate       : this
      menu           : @bound 'settingsMenu'
      style          : 'resurrection chat-dropdown'
      callback       : (event) -> @contextMenu event


  settingsMenu: ->

    menu =
      'Minimize'   : { callback : @getDelegate().bound 'end' }
      'Learn More' : { separator: yes, callback : -> kd.utils.createExternalLink 'https://koding.com/docs/collaboration' }

    isHost = not @isInSession

    if isHost
    then menu['End Session']   = { callback : => @parent.settingsPane.stopSession() }
    else menu['Leave Session'] = { callback : => @parent.settingsPane.leaveSession() }

    return menu


  createShareView: ->

    @addSubView wrapper = new KDCustomHTMLView
      tagName  : 'header'
      cssClass : 'share-view'
      partial  : """
        You can share this link on your Slack team.
      """
