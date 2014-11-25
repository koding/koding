class IDE.ChatParticipantView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'participant-view'

    super options, data

    account          = @getData()
    {nickname}       = account.profile
    {isOnline, isMe} = @getOptions()

    if isOnline then @setClass 'online' else @setClass 'offline'
    @setClass 'me'  if isMe

    @avatar    = new AvatarView
      origin   : nickname
      size     : width: 32, height: 32

    @name = new KDCustomHTMLView
      cssClass : 'name'
      partial  : nickname

    if isMe
      @watchButton = new KDCustomHTMLView cssClass: 'hidden'
      @settings    = new KDCustomHTMLView cssClass: 'hidden'
    else
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


  pistachio: ->
    return """
      {{> @avatar}}
      {{> @name}}
      <div class="settings">
        {{> @watchButton}}
        {{> @settings}}
      <div>
    """
