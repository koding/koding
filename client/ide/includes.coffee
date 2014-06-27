module.exports = [

  # namespacing
  "namespaces.coffee"

  # finder
  "finder/idevmitem.coffee"

  # workspace
  "workspace/workspacetabview.coffee"
  "workspace/workspacelayoutbuilder.coffee"
  "workspace/panel.coffee"
  "workspace/workspace.coffee"

  "workspace/panes/pane.coffee"
  "workspace/panes/editorpane.coffee"
  "workspace/panes/terminalpane.coffee"
  "workspace/panes/drawingpane.coffee"
  "workspace/panes/previewpane.coffee"
  "workspace/panes/finderpane.coffee"
  "workspace/panes/vmlistpane.coffee"

  # settings
  "workspace/panes/settings/editorsettings.coffee"
  "workspace/panes/settings/terminalsettings.coffee"
  "workspace/panes/settings/idesettingsview.coffee"
  "workspace/panes/settings/editorsettingsview.coffee"
  "workspace/panes/settings/terminalsettingsview.coffee"
  "workspace/panes/settings/settingspane.coffee"

  # views
  "views/tabview/idefilestabview.coffee"
  "views/tabview/ideview.coffee"
  "views/tabview/idesocialstabview.coffee"

  # file finder
  "views/idefilefinderitem.coffee"
  "views/idefilefinder.coffee"

  # shortcuts view
  "views/shortcutsview/shortcutview.coffee"
  "views/shortcutsview/shortcutsview.coffee"

  # status bar
  "views/statusbar/syntaxselectormenuitem.coffee"
  "views/statusbar/statusbarmenu.coffee"
  "views/statusbar/statusbar.coffee"

  "AppController.coffee"

  # stylus
  "styl/ide.finder.styl"
  "styl/ide.styl"
]