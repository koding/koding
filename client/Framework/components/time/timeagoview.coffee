class KDTimeAgoView extends KDView

  @registerStaticEmitter()

  KD.utils.repeat 60000, => @emit "OneMinutePassed"

  constructor: (options = {}, data) ->

    options.tagName = 'time'

    super options, data

    KDTimeAgoView.on "OneMinutePassed", => @updatePartial $.timeago @getData()

  viewAppended: ->
    @setPartial $.timeago @getData()
