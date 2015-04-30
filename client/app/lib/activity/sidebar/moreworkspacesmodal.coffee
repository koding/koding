kd                 = require 'kd'
KDButtonView       = kd.ButtonView
KDModalView        = kd.ModalView
ModalWorkspaceItem = require './modalworkspaceitem'


module.exports = class MoreWorkspacesModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'more-modal more-workspaces', options.cssClass
    options.title    = "Workspaces on #{data.first.machineLabel}"
    options.width    = 462
    options.overlay  = yes

    super options, data

    @addButton = new KDButtonView
      title    : 'Add Workspace'
      style    : 'add-big-btn'
      loader   : yes
      callback : =>
        @emit 'NewWorkspaceRequested'
        @destroy()

    @addSubView @addButton, '.kdmodal-content'

    for workspace in @getData()
      @addSubView view = new ModalWorkspaceItem {}, workspace
      view.once 'ModalItemSelected', @bound 'destroy'
