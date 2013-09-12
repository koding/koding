class KDDiaScene extends JView

  constructor:->
    super
      cssClass : 'kddia-scene'
      bind     : 'mousemove'

    @dias        = {}
    @containers  = []
    @connections = []

  diaAdded:(container, diaObj)->
    diaObj.on 'JointRequestsLine', @bound "handleLineRequest"
    diaObj.on 'DragInAction',      @bound "updateScene"
    diaObj.setX 20 + (Object.keys(container.dias).length-1) * 80
    diaObj.setY 20

  addContainer:(container)->
    container.on 'NewDiaObjectAdded', @bound 'diaAdded'
    container.on 'DragInAction', @bound "updateScene"
    @containers.push container
    @addSubView container
    container.setX 20 + (@containers.length - 1) * 320

  drawLine:(options={})->
    {sx,sy,ex,ey} = options
    canvas = document.getElementById 'fakeCanvas'
    canvas.width = canvas.width
    context = canvas.getContext '2d'
    context.beginPath()
    context.moveTo sx, sy
    context.lineTo ex, ey
    context.lineWidth = 5
    context.strokeStyle = 'blue'
    context.lineCap = 'round'
    context.stroke()

  mouseMove:(e)->
    return  unless @_trackJoint
    {x, y} = @_trackJoint.getPos()# @_trackJoint
    [ex, ey] = [x + (e.clientX - @_trackJoint.getX()) - 10, y + (e.clientY - @_trackJoint.getY()) - 7]
    @drawLine {sx:x, sy:y, ex, ey}

  mouseUp:(e)->
    return  unless @_trackJoint
    targetId = $(e.target).attr("dia-id")
    sourceId = @_trackJoint.getDiaId()
    delete @_trackJoint

    # Cleanup fake scene
    canvas = document.getElementById 'fakeCanvas'
    canvas.width = canvas.width

    if targetId
      log "Connect #{sourceId} to #{targetId}"
      source = @getDia sourceId
      target = @getDia targetId
      @connect source, target

  getDia:(id)->
    parts = ( id.match /dia\-((.*)\-joint\-(.*)|(.*))/ ).filter (m)->return !!m
    return null  unless parts
    [objId, jointType] = parts.slice(-2)
    return null  if  objId is jointType
    # Find a better way for this
    for container in @containers
      break  if dia = container.dias[objId]
    return {dia, jointType, container}

  viewAppended:->
    super
    @addContainer new KDDiaContainer
    @addContainer new KDDiaContainer

  handleLineRequest:(joint)->
    @_trackJoint = joint

  connect:(source, target)->
    if source and target
      @connections.push {source, target}
      @updateScene()

  updateScene:->
    canvas = document.getElementById 'jointCanvas'
    canvas.width = canvas.width
    context = canvas.getContext '2d'
    context.beginPath()
    #console.log @circle.joint.getRelativeX(), @circle.joint.getRelativeY()

    #[cPos, sPos] = [@circle.getJointPos(), @square.getJointPos()]
    for connection in @connections
      {source, target} = connection
      #log connection
      sJoint = source.dia.getJointPos source.jointType
      eJoint = target.dia.getJointPos target.jointType

      context.moveTo sJoint.x, sJoint.y
      sdiff = if source.jointType is 'right' then 50 else -50
      ediff = if target.jointType is 'right' then -50 else 50
      context.bezierCurveTo(sJoint.x+sdiff, sJoint.y, eJoint.x-ediff, eJoint.y, eJoint.x, eJoint.y)

    #context.moveTo(0, 0)
    #context.lineTo(100, 160)


    #context.quadraticCurveTo(230, 130, sPos.x, sPos.y+add)
    #context.bezierCurveTo(290, -10, 300, 100, sPos.x, sPos.y)
    #context.lineTo(500, 90)

    context.lineWidth = 5
    context.strokeStyle = 'red'
    context.stroke()

  pistachio:->
    """
    <canvas id="jointCanvas" width="1200" height="500"></canvas>
    <canvas id="fakeCanvas"  width="1200" height="500"></canvas>
    """

    # Example
    # app = new KDView cssClass: 'dia'
    # app.addSubView scene = new KDDiaScene
    # #scene.addContainer new KDDiaContainer
    # appView.addSubView app