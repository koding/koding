class MoreWorkspacesModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass            = KD.utils.curry 'more-modal more-workspaces', options.cssClass
    options.width               = 462
    options.title             or= 'Workspaces'
    options.disableSearch       = yes
    options.itemClass         or= ModalWorkspaceItem
    options.bindModalDestroy    = no

    super options, data

    @addButton = new KDButtonView
      title    : "Add Workspace"
      style    : 'solid green small'
      loader   : yes
      callback : =>
        @emit 'NewWorkspaceRequested'
        @destroy()

    @addSubView @addButton, '.kdmodal-title'


  populate: ->

    for workspace in @getData()
      @listController.addItem workspace
