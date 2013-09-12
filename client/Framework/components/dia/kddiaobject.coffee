class KDDiaObject extends JView

  constructor:(options, data)->
    options.cssClass = "kddia-object #{options.type}"
    options.draggable = yes
    super options, data

    @joints = {}
    @domElement.attr "dia-id", "dia-#{@getId()}"

  addJoint:(type)->
    @joints[type]?.destroy?()
    @addSubView joint = new KDDiaJoint {type}
    @joints[type] = joint

  drag:(event, delta)->
    super
    [m, p] = [@getBounds(), @parent.getBounds()]
    if p.x - m.x > 0 then @setX 0
    if p.y - m.y > 0 then @setY 0
    if m.x + m.w > p.x + p.w then @setX p.w - m.w
    if m.y + m.h > p.y + p.h then @setY p.h - m.h
    @emit 'DiaObjectDragged'

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
