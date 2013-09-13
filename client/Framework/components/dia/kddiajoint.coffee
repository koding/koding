class KDDiaJoint extends JView

  constructor:(options={}, data)->
    options.type   or= 'left'
    options.cssClass = "kddia-joint #{options.type}"
    super options, data

  viewAppended:->
    super
    @domElement.attr "dia-id", @getDiaId()

  getDiaId:->
    type = @getOption 'type'
    "dia-#{@parent.getId()}-joint-#{type}"

  getPos:->
    @parent.getJointPos this

  mouseDown:(e)->
    e.preventDefault()
    @parent.emit "JointRequestsLine", this
    return no
