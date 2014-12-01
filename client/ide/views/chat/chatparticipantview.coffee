class IDE.ChatParticipantView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'participant-view'

    super options, data

    {@isInSession} = options

    @createElements()


  createElements: ->

    { account, channel } = @getData()
    { nickname }         = account.profile
    { isOnline, isMe }   = @getOptions()

    if isOnline then @setClass 'online' else @setClass 'offline'
    @setClass 'me'  if isMe

    @avatar    = new AvatarView
      origin   : nickname
      size     : width: 32, height: 32

    @name = new KDCustomHTMLView
      cssClass : 'name'
      partial  : nickname

    @kickButton = new KDCustomHTMLView cssClass: 'hidden'

    if isMe
      @watchButton = new KDCustomHTMLView cssClass: 'hidden'
      @settings    = new KDCustomHTMLView cssClass: 'hidden'
    else
      unless @isInSession
        @kickButton  = new KDButtonView
          title    : 'KICK'
          cssClass : 'kick-button'
          callback : @bound 'kickParticipant'

      @watchButton = new KDButtonView
        iconOnly : 'yes'
        cssClass : 'watch-button'
        callback : =>
          @watchButton.toggleClass 'watching'
          log 'watch/unwatch user'

      @settings       = new KDSelectBox
        defaultValue  : 'edit'
        selectOptions : [
          { title : 'CAN READ', value : 'read'}
          { title : 'CAN EDIT', value : 'edit'}
        ]


  kickParticipant: ->

    { account, channel } = @getData()

    { kickParticipants } = KD.singletons.socialapi.channel

    options = { channelId: channel.id, accountIds: [account.socialApiId] }

    kickParticipants options, (err, result) =>

      return KD.showError err  if err

      channel.emit 'RemovedFromChannel', account


  setAsOnline: ->

    @unsetClass 'offline'
    @setClass   'online'


  pistachio: ->
    return """
      {{> @avatar}}
      {{> @name}}
      <div class="settings">
        {{> @kickButton}}
        {{> @watchButton}}
        {{> @settings}}
      <div>
    """
