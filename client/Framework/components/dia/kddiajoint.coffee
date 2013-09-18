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
    @parent.on 'HighlightJoint',    @bound 'showDeleteButton'
    @parent.on 'UnhighlightJoints', @bound 'hideDeleteButton'

  getDiaId:->
    "dia-#{@parent.getId()}-joint-#{@type}"

  getPos:->
    @parent.getJointPos this

  mouseDown:(e)->
    e.preventDefault()
    @parent.emit "JointRequestsLine", this
    return no

  showDeleteButton:(type)->
    return  unless type is this.type

    @deleteButton?.destroy()
    @addSubView @deleteButton = new KDButtonView title: 'Delete'
    @setSize width: 32, height: 16

  hideDeleteButton:->
    @deleteButton?.destroy()
    @setSize width: @getOption('size'), height: @getOption('size')
