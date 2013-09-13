class KDDiaObject extends JView

  constructor:(options, data)->
    options.cssClass = "kddia-object #{options.type}"

    options.draggable or= {}
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
    type = @getOption 'type'
    @addJoint 'right'
    if type is 'square'
      @addJoint 'left'

  getJointPos:(joint)->
    if typeof joint is "string"
      joint = @joints[joint]
    return {x:0, y:0}  unless joint
    [ x , y  ] = [@parent.getRelativeX() + @getRelativeX(),
                  @parent.getRelativeY() + @getRelativeY()]
    [ jx, jy ] = [joint.getRelativeX(), joint.getRelativeY()]
    x:x + jx + 10, y: y + jy + 7
