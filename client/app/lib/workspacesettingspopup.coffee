remote = require('./remote').getInstance()
showError = require './util/showError'
kd = require 'kd'
KDView = kd.View
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDModalViewWithForms = kd.ModalViewWithForms
GuidesLinksView = require './guideslinksview'
KodingSwitch = require './commonviews/kodingswitch'


module.exports = class WorkspaceSettingsPopup extends KDModalViewWithForms

  constructor:(options = {}, data)->

    options         = kd.utils.extend options,
      title         : "Workspace settings"
      cssClass      : 'activity-modal ws-settings'
      content       : ""
      overlay       : yes
      width         : 268
      height        : 'auto'
      arrowTop      : no
      tabs          : forms: Settings: fields:
        guides      :
          label     : "Related Guides"
          itemClass : GuidesLinksView
          links     : "Understanding Workspaces" : "https://koding.com/docs/getting-started-workspaces"

    super options, data

  viewAppended:->

    navItem   = @getDelegate()
    workspace = navItem.getData()
    deleteRelatedFiles = no

    @addSubView @buttonContainer = new KDCustomHTMLView tagName : 'ul'

    @buttonContainer.addSubView button = new KDCustomHTMLView tagName : 'li'
    button.addSubView @deleteButton = new KDButtonView
      style    : 'solid compact red delete-ws-modal'
      title    : 'Delete Workspace'
      loader   : yes
      callback : =>
        @deleteButton.showLoader()

        wsId = workspace.getId()
        remote.api.JWorkspace.deleteById wsId, (err)=>

          return  if showError err

          { machineUId, rootPath } = workspace
          { router, appManager   } = kd.singletons

          if deleteRelatedFiles
            methodName = 'deleteWorkspaceRootFolder'
            appManager.tell 'IDE', methodName, machineUId, rootPath

          @emit 'WorkspaceDeleted', wsId

          navItem.destroy()
          @destroy()

          router.handleRoute "/IDE/#{workspace.machineLabel}/my-workspace"

    @buttonContainer.addSubView field = new KDCustomHTMLView
        tagName : 'li'
        cssClass : 'delete-files'

    title = new KDCustomHTMLView
        tagName  : 'label'
        partial  : 'also delete its files'
        cssClass : "kdlabel"

    fieldSwitch = new KodingSwitch
        defaultValue  : deleteRelatedFiles
        cssClass      : 'tiny'
        callback      : (state) -> deleteRelatedFiles = state

    field.addSubView title
    field.addSubView fieldSwitch

    _addSubView = KDView::addSubView.bind this

    _addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position : top : 40
