class KDDiaScene extends JView

  # Example usage:
  #
  # @addSubView scene = new KDDiaScene

  # scene.addSubView container1 = new KDDiaContainer draggable : yes
  # scene.addSubView container2 = new KDDiaContainer
  # scene.addSubView container3 = new KDDiaContainer draggable : yes

  # container1.addSubView diaObject1 = new KDDiaObject type:'square'
  # container1.addSubView diaObject2 = new KDDiaObject type:'square'
  # container1.addSubView diaObject3 = new KDDiaObject type:'square'

  # container2.addSubView diaObject4 = new KDDiaObject type:'circle'
  # container2.addSubView diaObject5 = new KDDiaObject type:'circle'
  # container2.addSubView diaObject6 = new KDDiaObject type:'square'

  # container3.addSubView diaObject7 = new KDDiaObject type:'square'

  # scene.connect {dia:diaObject1, joint:'bottom'}, \
  #               {dia:diaObject2, joint:'bottom'}
  # scene.connect {dia:diaObject2, joint:'top'},    \
  #               {dia:diaObject3, joint:'top'}
  # scene.connect {dia:diaObject3, joint:'bottom'}, \
  #               {dia:diaObject7, joint:'bottom'}
  # scene.connect {dia:diaObject3, joint:'right'},  \
  #               {dia:diaObject4, joint:'left'}
  # scene.connect {dia:diaObject4, joint:'bottom'}, \
  #               {dia:diaObject6, joint:'bottom'}
  # scene.connect {dia:diaObject6, joint:'top'},    \
  #               {dia:diaObject7, joint:'top'}

  constructor:(options = {}, data)->
    options.cssClass = KD.utils.curry 'kddia-scene', options.cssClass
    options.bind     = KD.utils.curry 'mousemove',   options.bind

    super

    @containers  = []
    @connections = []
    @activeDias  = []

  diaAdded:(container, diaObj)->
    diaObj.on 'JointRequestsLine', @bound "handleLineRequest"
    diaObj.on 'DragInAction', => @setActiveDia diaObj

  addContainer:(container, pos = {})->
    @addSubView container

    container.on "NewDiaObjectAdded", @bound "diaAdded"
    container.on "HighlightLines", @bound "setActiveDia"
    container.on "DragInAction", @bound "updateScene"
    @containers.push container

    container.setX pos.x  if pos.x?
    container.setY pos.y  if pos.y?

  drawFakeLine:(options={})->
    {sx,sy,ex,ey,lineStyle} = options
    lineStyle or= {}
    canvas = document.getElementById 'fakeCanvas'
    canvas.width = canvas.width
    context = canvas.getContext '2d'
    context.beginPath()
    context.moveTo sx, sy
    context.lineTo ex, ey
    context.lineWidth = 2
    context.strokeStyle = 'orange'
    context.lineCap = 'round'
    context.stroke()

  mouseMove:(e)->
    return  unless @_trackJoint
    {x, y} = @_trackJoint.getPos()
    ex = x + (e.clientX - @_trackJoint.getX())
    ey = y + (e.clientY - @_trackJoint.getY())
    @drawFakeLine {sx:x, sy:y, ex, ey}

  mouseUp:(e)->
    return  unless @_trackJoint
    targetId = $(e.target).closest(".kddia-object").attr('dia-id')
    sourceId = @_trackJoint.getDiaId()
    delete @_trackJoint

    # Cleanup fake scene
    canvas = document.getElementById 'fakeCanvas'
    canvas.width = canvas.width

    if targetId
      log "Connect #{sourceId} to #{targetId}"
      source = @getDia sourceId
      target = @getDia targetId
      target.joint = @guessJoint target, source  unless target.joint
      @connect source, target

  guessJoint:(target, source)->
    return 'left'  if source.joint is 'right' and target.dia.joints.left?
    return 'right' if source.joint is 'left'  and target.dia.joints.right?

  getDia:(id)->
    parts = ( id.match /dia\-((.*)\-joint\-(.*)|(.*))/ ).filter (m)->return !!m
    return null  unless parts
    [objId, joint] = parts.slice(-2)
    joint = null  if objId is joint
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
      context.lineWidth = 2
      context.stroke()

  dumpScene:->
    log @containers, @connections

  pistachio:->
    """
    <canvas id="jointCanvas" width="1200px" height="500px"></canvas>
    <canvas id="fakeCanvas"  width="1200px" height="500px"></canvas>
    """
