class KDDiaObject extends JView

  constructor:(options, data)->
    options.cssClass = "kddia-object #{options.type}"

    options.draggable = {}  unless 'object' is typeof options.draggable
    options.draggable.containment or= {}
    options.draggable.containment.view or= 'parent'
    options.draggable.containment.padding ?= x:10, y:10

    super options, data

    @joints = {}
    @domElement.attr "dia-id", "dia-#{@getId()}"

  mouseDown:->
    super
    @emit "DiaObjectClicked"

  addJoint:(type)->
    @joints[type]?.destroy?()
    @addSubView joint = new KDDiaJoint {type}
    @joints[type] = joint

  viewAppended:->
    super
    type = @getOption 'type'
    @addJoint 'bottom'
    @addJoint 'right'
    @addJoint 'left'
    @addJoint 'top'

  getJointPos:(joint)->
    if typeof joint is "string"
      joint = @joints[joint]
    return {x:0, y:0}  unless joint
    [ x , y  ] = [@parent.getRelativeX() + @getRelativeX(),
                  @parent.getRelativeY() + @getRelativeY()]
    [ jx, jy ] = [joint.getRelativeX(), joint.getRelativeY()]
    [ dx, dy ] = if joint.type in ['left', 'right'] then [10, 2] else [2, 10]
    x:x + jx + dx, y: y + jy + dy
