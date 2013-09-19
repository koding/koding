class KDDiaJoint extends JView

  types = ['left', 'right', 'top', 'bottom']

  constructor:(options={}, data)->

    options.type   or= 'left'
    unless options.type in types
      warn "Unknown joint type '#{options.type}', falling back to 'left'"
      options.type = 'left'

    options.size    ?= 10
    options.cssClass = \
      KD.utils.curry "kddia-joint #{options.type}", options.cssClass

    super options, data

    @type = @getOption 'type'
    @size = @getOption 'size'

  viewAppended:->
    super
    @domElement.attr "dia-id", @getDiaId()

  getDiaId:->
    "dia-#{@parent.getId()}-joint-#{@type}"

  getPos:->
    @parent.getJointPos this

  click:(e)->
    @emit 'DeleteRequested', @type  if @inDeleteMode()
    @utils.stopDOMEvent e

  mouseDown:(e)->
    return  if @inDeleteMode()
    @utils.stopDOMEvent e
    @parent.emit "JointRequestsLine", this
    return no

  inDeleteMode:->
    @hasClass 'deleteMode'

  showDeleteButton:->
    @setClass 'deleteMode'

  hideDeleteButton:->
    @unsetClass 'deleteMode'