class KDDiaJoint extends JView

  types = ['left', 'right', 'top', 'bottom']

  constructor:(options={}, data)->

    options.type   or= 'left'
    unless options.type in types
      warn "Unknown joint type '#{options.type}', falling back to 'left'"
      options.type = 'left'

    options.cssClass = "kddia-joint #{options.type}"
    super options, data

    @type = @getOption 'type'

  viewAppended:->
    super
    @domElement.attr "dia-id", @getDiaId()

  getDiaId:->
    "dia-#{@parent.getId()}-joint-#{@type}"

  getPos:->
    @parent.getJointPos this

  mouseDown:(e)->
    e.preventDefault()
    @parent.emit "JointRequestsLine", this
    return no
