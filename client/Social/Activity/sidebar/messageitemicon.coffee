class SidebarMessageItemIcon extends JView

  constructor: (options = {}, data) ->

    options.tagName    = 'span'
    options.cssClass or= 'sidebar-message-icon'
    options.size     or= { width: 24, height: 24 }

    super options, data

    @init()


  init: ->

    { participantCount, participantsPreview } = @getData()

    shouldBeGrouped = no

    if participantCount is 1
      sample = participantsPreview
    else
      sample = participantsPreview.filter (acc) -> return acc._id isnt KD.whoami()._id
      shouldBeGrouped = yes  if participantCount > 2

    origin = sample.first

    if shouldBeGrouped
    then @createGrouped()
    else @createSingle origin

  createSingle: (origin) ->

    { width, height, cssClass } = @getOptions().size

    origin = { constructorName : 'JAccount', id : origin._id }

    @icon = new AvatarStaticView
      size       : { width, height }
      cssClass   : cssClass
      showStatus : yes
      origin     : origin


  createGrouped: ->

    @icon = new KDCustomHTMLView
      tagName  : 'span'

    @setClass 'stacked'

    { width, height, cssClass } = @getOptions().size

    @getParticipantOrigins (origins) =>

      for i in [origins.length - 1..0]
        @icon.addSubView new AvatarStaticView
          size       : { width, height }
          cssClass   : cssClass
          showStatus : yes
          origin     : origins[i]


  getParticipantOrigins: (callback) ->

    { lastMessage, participantsPreview, participantCount } = @getData()

    lastMessageOwner = lastMessage.account

    origins  = [lastMessageOwner]

    filtered = participantsPreview.filter (p) ->
      return not (p._id in [KD.whoami()._id, lastMessageOwner._id])

    origins = origins.concat filtered.slice 0, 2
    origins = origins.map (origin) -> { constructorName : 'JAccount', id : origin._id }

    callback origins


  pistachio: -> "{{> @icon}}"


