remote = require('./remote').getInstance()
showError = require './util/showError'
kd = require 'kd'
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
          links     : "Understanding Workspaces" : "http://learn.koding.com/guides/getting-started/workspaces/"

    super options, data

  viewAppended:->

    navItem   = @getDelegate()
    workspace = navItem.getData()
    deleteRelatedFiles = no

    @addSubView @buttonContainer = new KDCustomHTMLView tagName : 'ul'

    @buttonContainer.addSubView button = new KDCustomHTMLView tagName : 'li'
    button.addSubView @deleteButton = new KDButtonView
      style    : 'solid compact red'
      title    : 'Delete Workspace'
      callback : =>

        remote.api.JWorkspace.deleteById workspace.id, (err)=>

          return  if showError err

          { machineUId, rootPath } = workspace.data
          if deleteRelatedFiles
            kd.getSingleton('appManager').tell 'IDE', "deleteWorkspaceRootFolder", machineUId, rootPath 

          navItem.destroy()
          @destroy()

          kd.singletons
            .router.handleRoute "/IDE/#{workspace.machineLabel}/my-workspace"

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

    @addSubView new KDCustomHTMLView
      cssClass : 'modal-arrow'
      position : top : 34
