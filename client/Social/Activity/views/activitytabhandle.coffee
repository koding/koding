class ActivityTabHandle extends KDTabHandleView

  constructor: (options, data) ->
    options.cssClass = KD.utils.curry 'filter', options.cssClass

    super options, data

  partial: -> ''

  viewAppended: ->
    { pane } = @getOptions()
    { name: title, route: href } = pane.getOptions()

    @addSubView new CustomLinkView { title, href }
