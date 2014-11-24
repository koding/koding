class IDE.ChatParticipantView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'participant-view'

    super options, data

    participantData = @getData()
    participantName = participantData.nickname

    @avatar    = new AvatarView
      origin   : participantData.nickname
      size     : width: 32, height: 32

    @name = new KDCustomHTMLView
      cssClass : 'name'
      partial  : participantName

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
