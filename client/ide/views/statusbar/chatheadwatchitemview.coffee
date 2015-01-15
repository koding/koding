class ChatHeadWatchItemView extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.partial = 'Watch'

    super options, data

    { isWatching, nickname } = @getOptions()

    @addSubView @toggle = new KodingSwitch
      cssClass     : 'tiny'
      defaultValue : isWatching
      callback     : (state) =>
        @getDelegate().setWatchState state, nickname

    @addSubView @info = new CustomLinkView
      title        : ''
      cssClass     : 'info'
      href         : 'http://learn.koding.com/collaboration#watch'
      target       : '_blank'






module.exports = ChatHeadWatchItemView
