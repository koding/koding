class PaymentModal extends KDModalView

  initialState :
    interval   : PaymentWorkflow.interval.MONTH
    scene      : 0

  constructor: (options = {}, data) ->

    { state } = options

    @state = @utils.extend @initialState, state

    super options, data

    @initScenes()
    @initViews()


  initScenes: ->

    @scenes = [
      title      : 'Upgrade your plan'
      subtitle   : 'And get some things you know such and such'
      sceneClass : PaymentForm
      events     : ->
        @forwardEvent @scene, 'PaymentSubmitted'
    ,
      title       : ''
      subtitle    : ''
      sceneClass : PaymentForm
    ]


  openScene: (sceneNumber, options = {}) ->

    @scene?.destroy()

    { title, subtitle, sceneClass, events } = @scenes[sceneNumber]

    @setTitle title
    @setSubtitle subtitle

    @scene = new sceneClass options, @state

    events.call this # coming from the events property of scene array

    @addSubView @scene


  initViews: -> @scene = @openScene @initialState.scene


