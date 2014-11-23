class IDE.StatusBar extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'status-bar'

    super options, data

    {appManager} = KD.singletons

    @participantAvatars = {}

    @on 'ShowAvatars',       @bound 'showAvatars'
    @on 'ParticipantLeft',   @bound 'removeParticipantAvatar'
    @on 'ParticipantJoined', @bound 'addParticipantAvatar'


    @addSubView @status = new KDCustomHTMLView cssClass : 'status'

    @addSubView new KDCustomHTMLView
      partial  : '<cite></cite>'
      cssClass : 'icon help'
      click    : -> new HelpSupportModal

    @addSubView new KDCustomHTMLView
      partial  : '<cite></cite>'
      cssClass : 'icon github'
      click    : -> KD.utils.createExternalLink 'https://github.com/koding/IDE'

    @addSubView new KDCustomHTMLView
      partial  : '<cite></cite>'
      cssClass : 'icon shortcuts'
      click    : -> KD.getSingleton('appManager').tell 'IDE', 'showShortcutsView'

    @addSubView new KDCustomHTMLView
      partial  : '<cite></cite>'
      cssClass : 'icon participants'
      click    : => @emit 'ParticipantsModalRequired'

    @addSubView @share = new CustomLinkView
      href     : "#{KD.singletons.router.getCurrentPath()}/share"
      title    : 'Share'
      cssClass : 'share fr hidden'
      click    : (event) ->
        KD.utils.stopDOMEvent event
        appManager.tell 'IDE', 'showChat'
        # @hide()

    @addSubView @avatars = new KDCustomHTMLView
      cssClass : 'avatars fr hidden'
      click    : (event) ->
        KD.utils.stopDOMEvent event
        appManager.tell 'IDE', 'showChat'
        # @hide()


  showInformation: ->

    @status.updatePartial 'Click the plus button above to create a new panel'


  createParticipantAvatar: (nickname) ->

    view       = new AvatarView
      origin   : nickname
      tooltip  : title: nickname
      size     : width: 24, height: 24

    @participantAvatars[nickname] = view
    @avatars.addSubView view
    view.getElement().removeAttribute 'href'


  showAvatars: (participants) ->

    @avatars.show()

    for participant in participants
      {nickname} = participant
      @createParticipantAvatar nickname


  removeParticipantAvatar: (nickname) ->

    @participantAvatars[nickname]?.destroy()
    delete @participantAvatars[nickname]


  addParticipantAvatar: (nickname) ->

    return if @participantAvatars[nickname]

    @createParticipantAvatar nickname
