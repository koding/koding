class KDTimeAgoView extends KDView

  KD.utils.repeat 5000, => @emit "OneMinutePassed"

  constructor: (options = {}, data) ->

    options.tagName = 'time'

    super options, data

    KDTimeAgoView.on "OneMinutePassed", =>
      oldDate   = new Date @getData()
      timestamp = oldDate.setMinutes oldDate.getMinutes() - 1

      @setData dateFormat timestamp, "UTC:yyyy-mm-dd'T'HH:MM:ss'Z'"

      @updatePartial $.timeago @getData()

  viewAppended: ->
    @setPartial $.timeago @getData()
