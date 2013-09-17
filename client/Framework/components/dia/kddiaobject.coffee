class KDDiaObject extends JView

  constructor:(options, data)->
    options.cssClass  = KD.utils.curry 'kddia-object', options.cssClass

    unless options.draggable?
      options.draggable = {}  unless 'object' is typeof options.draggable
      options.draggable.containment or= {}
      options.draggable.containment.view or= 'parent'
      options.draggable.containment.padding ?=
        top: 1, right: 1, bottom: 1, left: 1

    options.bind = KD.utils.curry 'mouseleave', options.bind
    options.joints ?= ['left', 'right']
    options.jointItemClass ?= KDDiaJoint

    super options, data

    @joints = {}
    @domElement.attr "dia-id", "dia-#{@getId()}"
    @wc = KD.getSingleton 'windowController'

  getDiaId:->
    @domElement.attr "dia-id"

  mouseDown:(e)->
    @emit "DiaObjectClicked"
    @_mouseDown = yes
    @wc.once 'ReceivedMouseUpElsewhere', => @_mouseDown = no
    @utils.stopDOMEvent e

  mouseLeave:(e)->
    return  unless @_mouseDown

    bounds = @getBounds()
    joint  = null

    if e.pageX >= bounds.x + bounds.w  # means right joint
      joint = @joints['right']
    if e.pageX <= bounds.x             # means left joint
      joint = @joints['left']
    if e.pageY >= bounds.y + bounds.h  # means bottom joint
      joint = @joints['bottom']
    if e.pageY <= bounds.y             # means top joint
      joint = @joints['top']

    if joint then @emit "JointRequestsLine", joint

  addJoint:(type)->
    warn "Tried to add same joint! Destroying old one. "  if @joints[type]?
    @joints[type]?.destroy?()
    jointItem = @getOption 'jointItemClass'
    @addSubView joint = new jointItem {type}
    @joints[type] = joint

  viewAppended:->
    super
    @addJoint joint for joint in @getOption 'joints'

  getJointPos:(joint)->
    if typeof joint is "string"
      joint = @joints[joint]
    return {x:0, y:0}  unless joint
    size = joint.size or 10
    [ x , y  ] = [@parent.getRelativeX() + @getRelativeX(),
                  @parent.getRelativeY() + @getRelativeY()]
    [ jx, jy ] = [joint.getRelativeX(), joint.getRelativeY()]
    [ dx, dy ] = if joint.type in ['left', 'right'] then [size, 2] else [2, size]
    x:x + jx + dx, y: y + jy + dy
