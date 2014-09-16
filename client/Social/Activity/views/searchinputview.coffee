class SearchInputView extends KDInputView

  constructor: (options, data) ->
    super options, data

    { event } = @getOptions()
    event ?= 'keydown'

    @on event, => @emit 'input', @getValue()
