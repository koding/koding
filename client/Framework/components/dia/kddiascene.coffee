class KDDiaScene extends JView

  constructor:->
    super
      cssClass : 'kddia-scene'
      bind     : 'mousemove'

    @containers  = []
    @connections = []
    @activeDias  = []

  diaAdded:(container, diaObj)->
    diaObj.on 'JointRequestsLine', @bound "handleLineRequest"
    diaObj.on 'DragInAction', => @setActiveDia diaObj
    diaObj.setX 20 + (Object.keys(container.dias).length-1) * 80
    diaObj.setY 20

  addSubView:(container)->
    super container
    container.on "NewDiaObjectAdded", @bound "diaAdded"
    container.on "HighlightLines", @bound "setActiveDia"
    container.on "DragInAction", @bound "updateScene"
    @containers.push container
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
    ex = x + (e.clientX - @_trackJoint.getX()) - 4
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
    [objId, joint] = parts.slice(-2)
    return null  if  objId is joint
    # Find a better way for this
    for container in @containers
      break  if dia = container.dias[objId]
    return {dia, joint, container}

  setActiveDia:(dia=[], update=yes)->
    if not Array.isArray dia then dia = [dia]
    @activeDias = dia
    @updateScene()  if update

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

      sJoint = source.dia.getJointPos source.joint
      tJoint = target.dia.getJointPos target.joint
      # context.setLineDash([5])
      context.moveTo sJoint.x, sJoint.y

      [sx, sy, tx, ty] = [0, 0, 0, 0]
      if source.joint in ['top', 'bottom']
        sy = if source.joint is 'top' then -50 else 50
      if source.joint in ['left', 'right']
        sx = if source.joint is 'left' then -50 else 50
      if target.joint in ['top', 'bottom']
        ty = if target.joint is 'top' then -50 else 50
      if target.joint in ['left', 'right']
        tx = if target.joint is 'left' then -50 else 50

      context.bezierCurveTo(sJoint.x + sx, sJoint.y + sy, \
                            tJoint.x + tx, tJoint.y + ty, \
                            tJoint.x, tJoint.y)
      context.lineWidth = 5
      context.stroke()

  dumpScene:->
    log @containers, @connections

  pistachio:->
    """
    <canvas id="jointCanvas" width="1200" height="500"></canvas>
    <canvas id="fakeCanvas"  width="1200" height="500"></canvas>
    """
