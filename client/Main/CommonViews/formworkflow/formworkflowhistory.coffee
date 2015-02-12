class FormWorkflow.History extends KDObject

  constructor: ->
    super()
    @state = -1
    @stack = []

  push: (provider) ->
    unless @stack[@state + 1] is provider
      @stack.push provider

    @emit 'Push', provider

    @inc()

  lastIndex: -> @stack.length - 1

  inc: (n = 1) ->
    @state = Math.min (Math.max 0, @state + n), @lastIndex()
    @state

  go: (n = 1) -> @stack[@inc n]

  back: -> @go -1

  next: -> @go 1