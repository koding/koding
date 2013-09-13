class KDDiaScene extends JView

  constructor:->
    super
      cssClass : 'kddia-scene'
      bind     : 'mousemove'

    @dias        = {}
    @containers  = []
    @connections = []
    @activeDias  = []

  diaAdded:(container, diaObj)->
    diaObj.on 'JointRequestsLine', @bound "handleLineRequest"
    diaObj.on 'DragInAction', => @setActiveDia diaObj
    diaObj.setX 20 + (Object.keys(container.dias).length-1) * 80
    diaObj.setY 20

  addContainer:(container)->
    container.on "NewDiaObjectAdded", @bound "diaAdded"
    container.on "HighlightLines", @bound "setActiveDia"
    container.on "DragInAction", @bound "updateScene"
    @containers.push container
    @addSubView container
    container.setX 20 + (@containers.length - 1) * 320

  drawFakeLine:(options={})->
    {sx,sy,ex,ey,lineStyle} = options
    lineStyle or= {}
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
    {x, y} = @_trackJoint.getPos()
    ex = x + (e.clientX - @_trackJoint.getX()) - 10
    ey = y + (e.clientY - @_trackJoint.getY()) - 7
    @drawFakeLine {sx:x, sy:y, ex, ey}

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

  setActiveDia:(dia=[], update=yes)->
    if not Array.isArray dia then dia = [dia]
    @activeDias = dia
    @updateScene()  if update

  viewAppended:->
    super
    @addContainer new KDDiaContainer
    @addContainer new KDDiaContainer

  handleLineRequest:(joint)->
    @_trackJoint = joint

  connect:(source, target)->
    if source and target
      return if source.dia.id is target.dia.id
      @connections.push {source, target}
      @setActiveDia target.dia

  updateScene:->
    canvas = document.getElementById 'jointCanvas'
    canvas.width = canvas.width
    context = canvas.getContext '2d'

    for connection in @connections
      context.beginPath()
      {source, target} = connection
      if (source.dia in @activeDias) or (target.dia in @activeDias)
        context.strokeStyle = 'green'
      else
        context.strokeStyle = '#ccc'
      sJoint = source.dia.getJointPos source.jointType
      eJoint = target.dia.getJointPos target.jointType

      context.moveTo sJoint.x, sJoint.y
      sdiff = if source.jointType is 'right' then 50 else -50
      ediff = if target.jointType is 'right' then -50 else 50
      context.bezierCurveTo(sJoint.x+sdiff, sJoint.y, eJoint.x-ediff, eJoint.y, eJoint.x, eJoint.y)
      context.lineWidth = 5
      context.stroke()

  pistachio:->
    """
    <canvas id="jointCanvas" width="1200" height="500"></canvas>
    <canvas id="fakeCanvas"  width="1200" height="500"></canvas>
    """
