class SidebarMessageItemText extends JView

  constructor: (options = {}, data) ->

    options.cssClass or= 'sidebar-message-text'

    super options, data

    @init()


  pistachio: -> "{{> @text}}"


  init: ->

    { purpose } = @getData()

    return @createPurpose purpose  if purpose

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


  createPurpose: (purpose) ->

    @text = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'purpose'
      partial  : purpose


  createSingle: (origin) ->

    origin = { constructorName : 'JAccount', id : origin._id }
    @text  = new ProfileTextView {origin}


  fetchParticipants: (callback) ->

    { lastMessage, participantsPreview, participantCount } = @getData()

    lastMessageOwner = lastMessage.account

    origins  = if lastMessageOwner._id is KD.whoami()._id then [] else [lastMessageOwner]

    filtered = participantsPreview.filter (p) ->
      return not (p._id in [KD.whoami()._id, lastMessageOwner._id])

    origins = (origins.concat filtered).slice 0, 3
    origins = origins.map (origin) -> { constructorName : 'JAccount', id : origin._id }

    KD.remote.cacheable origins, callback


  createGrouped: ->

    @text = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'profile'

    @fetchParticipants (err, participants) =>

      return KD.showError err  if err

      { participantCount } = @getData()

      nameCount = participants.length

      participants.forEach (participant, index) =>

        @addProfileElement participant
        @addTextElement partial: @getSeparatorPartial participantCount, nameCount, index

      @addPlusMoreElement participantCount, nameCount  if participantCount > nameCount + 1


  addPlusMoreElement: (participantCount, nameCount) ->

    return  unless participantCount > nameCount + 1

    @addTextElement partial: " #{participantCount - nameCount - 1} more"


  addTextElement: (options = {}, data) ->
    options.tagName = 'span'
    @text.addSubView new KDCustomHTMLView options, data


  addProfileElement: (data) ->

    @text.addSubView profileView = new ProfileTextView
      origin    : origin
      pistachio : "{{ #(profile.firstName)}}"

    return profileView


  getSeparatorPartial: (participantCount, nameCount, position) ->

    thereIsDifference = !!(participantCount - nameCount - 1)

    switch
      when (nameCount - position) is (if thereIsDifference then 1 else 2)
        return ' & '
      when position < nameCount - 1
        return ', '


