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
    options.showStatusIndicator ?= yes

    super options, data

    @joints = {}
    @domElement.attr "dia-id", "dia-#{@getId()}"
    @wc = KD.getSingleton 'windowController'

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

    if @joints[type]?
      warn "KDDiaObject: Tried to add same joint! Destroying old one. "
      @joints[type].destroy?()

    jointItemClass = @getOption 'jointItemClass'
    @addSubView joint = new jointItemClass {type}
    @joints[type] = joint

  getJointPos:(joint)->
    if typeof joint is "string"
      joint = @joints[joint]
    return {x:0, y:0}  unless joint
    [ x , y  ] = [@parent.getRelativeX() + @getRelativeX(),
                  @parent.getRelativeY() + @getRelativeY()]
    [ jx, jy ] = [joint.getRelativeX(), joint.getRelativeY()]
    [ dx, dy ] = if joint.type in ['left', 'right'] then [10, 2] else [2, 10]
    x:x + jx + dx, y: y + jy + dy

  addStatusIndicator:()->
    @addSubView @statusIndicator = new KDCustomHTMLView
      cssClass    : "status-indicator"
      click       : => @toggleStatus()

  toggleStatus:()->
    @toggleClass "passivated"
    @data.activated = !@data.activated
    @emit 'DiaObjectPassivated' if not @getData().activated

  viewAppended:->
    super

    @addJoint joint for joint in @getOption 'joints'
    @parent.on 'UnhighlightDias', =>
      @unsetClass 'highlight'
      joint.hideDeleteButton()  for key, joint of @joints

    if not @getData().activated
      KD.utils.wait 10, =>
        @setClass 'passivated'
        @emit 'DiaObjectPassivated'

    @addStatusIndicator() if @getOption "showStatusIndicator"

    window.asd = @

  getDiaId:->
    @domElement.attr "dia-id"
