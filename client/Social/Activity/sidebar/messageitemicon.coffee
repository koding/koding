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

    { width, height, cssClass } = @getOptions().size

    cssClass = KD.utils.curry cssClass, 'stacked'

    { lastMessage } = @getData()

    origin = { constructorName : 'JAccount', id : lastMessage.account._id }

    @icon = new AvatarStaticView
      size       : { width, height }
      cssClass   : cssClass


  pistachio: -> "{{> @icon}}"


