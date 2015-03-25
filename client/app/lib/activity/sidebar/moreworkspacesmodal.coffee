kd = require 'kd'
KDButtonView = kd.ButtonView
ModalWorkspaceItem = require './modalworkspaceitem'
SidebarSearchModal = require './sidebarsearchmodal'


module.exports = class MoreWorkspacesModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass            = kd.utils.curry 'more-modal more-workspaces', options.cssClass
    options.width               = 462
    options.title             or= "Workspaces on #{data.first.machineLabel}"
    options.disableSearch       = yes
    options.itemClass         or= ModalWorkspaceItem
    options.bindModalDestroy    = no

    super options, data

    @addButton = new KDButtonView
      title    : "Add Workspace"
      style    : 'add-big-btn'
      loader   : yes
      callback : =>
        @emit 'NewWorkspaceRequested'
        @destroy()

    @addSubView @addButton, '.kdmodal-content'

  populate: ->

    for workspace in @getData()
      item = @listController.addItem workspace
      item.once 'ModalItemSelected', @bound 'destroy'
