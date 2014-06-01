module.exports = [

  "editorsettings.coffee"
  "terminalsettings.coffee"

  # workspace
  "workspace/workspacetabview.coffee"
  "workspace/workspacelayoutbuilder.coffee"

  "workspace/panes/pane.coffee"
  "workspace/panes/editorpane.coffee"
  "workspace/panes/terminalpane.coffee"
  "workspace/panes/drawingpane.coffee"
  "workspace/panes/previewpane.coffee"
  "workspace/panes/finderpane.coffee"
  "workspace/panes/vmlistpane.coffee"
  "workspace/panes/settingspane.coffee"

  "workspace/panel.coffee"
  "workspace/workspace.coffee"

  # finder
  "finder/AppController.coffee",

  "finder/commonviews/DNDUploader.coffee",

  "finder/filetree/modals/openwith/openwithmodalitem.coffee",
  "finder/filetree/modals/openwith/openwithmodal.coffee",
  "finder/filetree/modals/vmdangermodalview.coffee",

  "finder/filetree/controllers/findercontroller.coffee",
  "finder/filetree/controllers/findertreecontroller.coffee",
  "finder/filetree/controllers/findercontextmenucontroller.coffee",

  "finder/filetree/itemviews/finderitem.coffee",
  "finder/filetree/itemviews/fileitem.coffee",
  "finder/filetree/itemviews/folderitem.coffee",
  "finder/filetree/itemviews/mountitem.coffee",
  "finder/filetree/itemviews/brokenlinkitem.coffee",
  "finder/filetree/itemviews/sectionitem.coffee",
  "finder/filetree/itemviews/vmitem.coffee",

  "finder/filetree/itemsubviews/finderitemdeleteview.coffee",
  "finder/filetree/itemsubviews/finderitemdeletedialog.coffee",
  "finder/filetree/itemsubviews/finderitemrenameview.coffee",
  "finder/filetree/itemsubviews/setpermissionsview.coffee",
  "finder/filetree/itemsubviews/vmtogglebuttonview.coffee",
  "finder/filetree/itemsubviews/mounttogglebuttonview.coffee",
  "finder/filetree/itemsubviews/copyurlview.coffee",

  "finder/fs/fshelper.coffee",
  "finder/fs/fswatcher.coffee",
  "finder/fs/fsitem.coffee",
  "finder/fs/fsfile.coffee",
  "finder/fs/fsfolder.coffee",
  "finder/fs/fsmount.coffee",
  "finder/fs/fsbrokenlink.coffee",
  "finder/fs/fsvm.coffee",
  "finder/fs/appswatcher.coffee",

  "finder/styl/resurrection.finder.styl"


  # ide
  "views/tabview/idefilestabview.coffee"
  "views/tabview/ideview.coffee"
  "views/tabview/idesocialstabview.coffee"

  "AppController.coffee"

  # stylus
  "styl/ide.styl"
]