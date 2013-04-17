class ChatAppController extends AppController

  KD.registerAppClass @,
    name         : "Chat"
    route        : "Chat"
    background   : yes

  constructor:(options, data)->
    super options, data

    @invitationChannel = createInvitationChannel()

  createInvitationChannel = ->
    KD.remote.subscribe 'invitation', {
      serviceType : 'invitation'
      isExclusive : yes
      isReadOnly  : yes
    }