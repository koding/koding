class KDTimeAgoView extends KDView

  KD.utils.repeat 5000, => @emit "OneMinutePassed"

  constructor: (options = {}, data) ->

    options.tagName = 'time'

    super options, data

    KDTimeAgoView.on "OneMinutePassed", => @updatePartial $.timeago @getData()

  viewAppended: ->
    @setPartial $.timeago @getData()
