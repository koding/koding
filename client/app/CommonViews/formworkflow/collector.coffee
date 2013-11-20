class FormWorkflow.Collector extends KDEventEmitter

  constructor: (@gate = new FormWorkflow.Gate) ->
    super()

    @data = KD.utils.dict()

    @gate.on 'status', (isSatisfied) =>
      if isSatisfied
        @emit 'DataCollected', @data
      else
        @emit 'Pending'

  addRequirement: (requirement) ->
    @gate.addField requirement

  nextRequirement: -> @gate.nextNode()

  getFields: (isDeep) -> @gate.getFields isDeep

  getData: -> @data

  collectData: (data) ->
    @defineKey key, val  for own key, val of data

  removeKey: (key) ->
    delete @data[key]
    @gate.removeKey key

  defineKey: (key, value) ->
    @data[key] = value
    @gate.satisfy key
