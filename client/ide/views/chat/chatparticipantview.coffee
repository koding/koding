class ChatParticipantView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'participant-view'

    super options, data

    @createElements()


  createElements: ->

    { isOnline, @isWatching, @isInSession, permission } = @getOptions()
    { account, channel } = @getData()
    { nickname }         = account.profile

    @amIHost = not @isInSession

    if isOnline then @setClass 'online' else @setClass 'offline'

    @avatar    = new AvatarView
      origin   : nickname
      size     : width: 32, height: 32

    @name = new KDCustomHTMLView
      cssClass : 'name'
      partial  : nickname

    @kickButton = new KDCustomHTMLView cssClass: 'hidden'

    if @amIHost
      @kickButton  = new KDButtonView
        title    : 'KICK'
        cssClass : 'kick-button'
        callback : @bound 'kickParticipant'

    @watchButton = new KDButtonView
      iconOnly : 'yes'
      cssClass : 'watch-button'
      tooltip  :
        title  : "Watch #{nickname}"
      callback : =>
        methodName  = if @isWatching then 'unwatchParticipant' else 'watchParticipant'
        @isWatching = not @isWatching

        @watchButton.toggleClass 'watching'
        KD.getSingleton('appManager').tell 'IDE', methodName, nickname

    @watchButton.setClass 'watching'  if @isWatching

    @permissions    = new KDSelectBox
      defaultValue  : permission
      disabled      : not @amIHost
      callback      : (permission) =>
        @emit 'ParticipantPermissionChanged', permission
      selectOptions : [
        { title : 'CAN READ', value : 'read'}
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
        {{> @permissions}}
      <div>
    """


module.exports = ChatParticipantView
