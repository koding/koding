class KDDiaScene extends JView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry "kddia-scene", options.cssClass
    options.bind     = KD.utils.curry "mousemove",   options.bind

    options.lineCap         or= "round"
    options.lineWidth        ?= 2
    options.lineColor       or= "#ccc"
    options.lineColorActive or= "orange"
    options.lineColorHelper or= "green"
    options.lineDashes       ?= []
    options.curveDistance    ?= 50

    super

    @containers   = []
    @connections  = []
    @activeDias   = []
    @activeJoints = []

  diaAdded:(container, diaObj)->
    diaObj.on "JointRequestsLine", @bound "handleLineRequest"
    diaObj.on "DragInAction",   => @setActiveDia diaObj

  addContainer:(container, pos = {})->
    @addSubView container

    container.on "NewDiaObjectAdded", @bound "diaAdded"
    container.on "HighlightLines",    @bound "setActiveDia"
    container.on "DragInAction",      @bound "updateScene"

    @containers.push container

    container.setX pos.x  if pos.x?
    container.setY pos.y  if pos.y?

    @createCanvas()

  drawFakeLine:(options={})->
    {sx,sy,ex,ey} = options

    @cleanup @fakeCanvas

    @fakeContext.beginPath()
    @fakeContext.moveTo sx, sy
    @fakeContext.lineTo ex, ey

    @fakeContext.lineCap     = @getOption "lineCap"
    @fakeContext.lineWidth   = @getOption "lineWidth"
    @fakeContext.strokeStyle = @getOption "lineColorHelper"

    @fakeContext.stroke()

  click:(e)->
    return if e.target isnt e.currentTarget
    @setActiveDia()

  mouseMove:(e)->
    return  unless @_trackJoint
    {x, y} = @_trackJoint.getPos()
    ex = x + (e.clientX - @_trackJoint.getX())
    ey = y + (e.clientY - @_trackJoint.getY())
    @drawFakeLine {sx:x, sy:y, ex, ey}

  mouseUp:(e)->
    return  unless @_trackJoint

    targetId = $(e.target).closest(".kddia-object").attr("dia-id")
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
    return "left"  if source.joint is "right" and target.dia.joints.left?
    return "right" if source.joint is "left"  and target.dia.joints.right?

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

    @deselectAllDias()

    if @activeDias.length is 1
      for connection in @connections
        {source, target} = connection
        if (source.dia in @activeDias) or (target.dia in @activeDias)
          [source, target].forEach (conn)=>
            joint = conn.dia.joints[conn.joint]
            if joint not in @activeJoints
              joint.showDeleteButton()
              joint.on 'DeleteRequested', @bound 'disconnectHelper'
              @activeJoints.push joint

    @updateScene()  if update

  deselectAllDias:->
    container.emit 'UnhighlightJoints' for container in @containers
    joint.off 'DeleteRequested'        for joint in @activeJoints
    @activeJoints = []

  handleLineRequest:(joint)->
    @_trackJoint = joint

  disconnectHelper:(dia, joint)->
    log "Delete", dia, joint

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
        @realContext.strokeStyle = @getOption 'lineColorActive'
      else
        @realContext.strokeStyle = @getOption 'lineColor'

      sJoint = source.dia.getJointPos source.joint
      tJoint = target.dia.getJointPos target.joint

      ld = @getOption 'lineDashes'
      @realContext.setLineDash ld  if ld.length > 0

      @realContext.moveTo sJoint.x, sJoint.y

      cd = @getOption 'curveDistance'
      [sx, sy, tx, ty] = [0, 0, 0, 0]
      if source.joint in ["top", "bottom"]
        sy = if source.joint is "top" then -cd else cd
      if source.joint in ["left", "right"]
        sx = if source.joint is "left" then -cd else cd
      if target.joint in ["top", "bottom"]
        ty = if target.joint is "top" then -cd else cd
      if target.joint in ["left", "right"]
        tx = if target.joint is "left" then -cd else cd

      @realContext.bezierCurveTo(sJoint.x + sx, sJoint.y + sy, \
                                 tJoint.x + tx, tJoint.y + ty, \
                                 tJoint.x, tJoint.y)

      @realContext.lineWidth = @getOption 'lineWidth'
      @realContext.stroke()

  createCanvas:->
    @realCanvas?.destroy()
    @fakeCanvas?.destroy()

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

  updateCanvasSize:->
    @realCanvas.setDomAttributes @getSceneSize()
    @fakeCanvas.setDomAttributes @getSceneSize()
    @updateScene()

  parentDidResize:->
    super
    do _.throttle => @updateCanvasSize()

  getSceneSize:-> width: @getWidth(), height: @getHeight()

  dumpScene:->
    log @containers, @connections
