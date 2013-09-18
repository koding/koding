class KDDiaScene extends JView

  constructor:(options = {}, data)->
    options.cssClass = KD.utils.curry 'kddia-scene', options.cssClass
    options.bind     = KD.utils.curry 'mousemove',   options.bind

    super

    @containers  = []
    @connections = []
    @activeDias  = []

  diaAdded:(container, diaObj)->
    diaObj.on 'JointRequestsLine', @bound "handleLineRequest"
    diaObj.on 'DragInAction',   => @setActiveDia diaObj

  addContainer:(container, pos = {})->
    @addSubView container

    container.on "NewDiaObjectAdded", @bound "diaAdded"
    container.on "HighlightLines",    @bound "setActiveDia"
    container.on "DragInAction",      @bound "updateScene"

    @containers.push container

    container.setX pos.x  if pos.x?
    container.setY pos.y  if pos.y?

  drawFakeLine:(options={})->
    {sx,sy,ex,ey} = options
    @cleanup @fakeCanvas

    @fakeContext.beginPath()
    @fakeContext.moveTo sx, sy
    @fakeContext.lineTo ex, ey
    @fakeContext.lineWidth = 2
    @fakeContext.strokeStyle = 'orange'
    @fakeContext.lineCap = 'round'
    @fakeContext.stroke()

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
    @cleanup @fakeCanvas

    return  unless targetId

    log "Connect #{sourceId} to #{targetId}"
    source = @getDia sourceId
    target = @getDia targetId
    target.joint = @guessJoint target, source  unless target.joint
    @connect source, target  if target.joint

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
    return  unless source and target
    return  if source.dia?.id is target.dia?.id
    @connections.push {source, target}
    @setActiveDia target.dia

  updateScene:->

    @cleanup @realCanvas

    for connection in @connections

      @realContext.beginPath()

      {source, target} = connection

      if (source.dia in @activeDias) or (target.dia in @activeDias)
        @realContext.strokeStyle = 'green'
      else
        @realContext.strokeStyle = '#ccc'

      sJoint = source.dia.getJointPos source.joint
      tJoint = target.dia.getJointPos target.joint
      # @realContext.setLineDash([5])
      @realContext.moveTo sJoint.x, sJoint.y

      [sx, sy, tx, ty] = [0, 0, 0, 0]
      if source.joint in ['top', 'bottom']
        sy = if source.joint is 'top' then -50 else 50
      if source.joint in ['left', 'right']
        sx = if source.joint is 'left' then -50 else 50
      if target.joint in ['top', 'bottom']
        ty = if target.joint is 'top' then -50 else 50
      if target.joint in ['left', 'right']
        tx = if target.joint is 'left' then -50 else 50

      @realContext.bezierCurveTo(sJoint.x + sx, sJoint.y + sy, \
                                 tJoint.x + tx, tJoint.y + ty, \
                                 tJoint.x, tJoint.y)
      @realContext.lineWidth = 2
      @realContext.stroke()

  viewAppended:->
    super
    @addSubView @realCanvas = new KDCustomHTMLView
      tagName    : "canvas"
      attributes : @getSceneSize()
    @realContext = @realCanvas.getElement().getContext "2d"
    @addSubView @fakeCanvas = new KDCustomHTMLView
      tagName    : "canvas"
      cssClass   : "fakeCanvas"
      attributes : @getSceneSize()
    @fakeContext = @fakeCanvas.getElement().getContext "2d"

  cleanup:(canvas)->
    canvas.setDomAttributes width: canvas.getWidth()

  getSceneSize:-> width: @getWidth(), height: @getHeight()

  dumpScene:->
    log @containers, @connections
