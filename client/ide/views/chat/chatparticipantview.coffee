class IDE.ChatParticipantView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'participant-view'

    super options, data

    {@isInSession} = options

    @createElements()


  createElements: ->

    { isOnline, @isWatching } = @getOptions()
    { account, channel }      = @getData()
    { nickname }              = account.profile

    if isOnline then @setClass 'online' else @setClass 'offline'

    @avatar    = new AvatarView
      origin   : nickname
      size     : width: 32, height: 32

    @name = new KDCustomHTMLView
      cssClass : 'name'
      partial  : nickname

    @kickButton = new KDCustomHTMLView cssClass: 'hidden'

    unless @isInSession
      @kickButton  = new KDButtonView
        title    : 'KICK'
        cssClass : 'kick-button'
        callback : @bound 'kickParticipant'

    @watchButton = new KDButtonView
      iconOnly : 'yes'
      cssClass : 'watch-button'
      callback : =>
        methodName  = if @isWatching then 'unwatchParticipant' else 'watchParticipant'
        @isWatching = not @isWatching

        @watchButton.toggleClass 'watching'
        KD.getSingleton('appManager').tell 'IDE', methodName, nickname

    @watchButton.setClass 'watching'  if @isWatching

    @settings       = new KDSelectBox
      defaultValue  : 'edit'
      selectOptions : [
        # { title : 'CAN READ', value : 'read'}
        { title : 'CAN EDIT', value : 'edit'}
      ]


  kickParticipant: ->

    KD.singletons.appManager.tell 'IDE', 'kickParticipants', @getData().account


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
