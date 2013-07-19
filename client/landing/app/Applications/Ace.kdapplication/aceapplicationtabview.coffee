class AceApplicationTabView extends ApplicationTabView

  removePane: (pane) ->
    {ace} = pane.getOptions().aceView
    file  = ace.getData()

    return @removePane pane  unless ace.isContentChanged()
    modal = new KDModalView
      cssClass      : "modal-with-text"
      title         : "Do you want to save your changes?"
      content       : "<p>Your changes will be lost if you don't save them.</p>"
      overlay       : yes
      buttons       :
        "SaveClose" :
          cssClass  : "modal-clean-gray"
          title     : "Save and Close"
          callback  : =>
            if file.path.indexOf("localfile:") is 0
              file.once "fs.saveAs.finished", => @removePane pane
              ace.requestSaveAs()
              modal.destroy()
            else
              ace.requestSave()
              @closePaneAndModal pane, modal
        "DontSave"  :
          cssClass  : "modal-clean-gray"
          title     : "Don't Save"
          callback  : =>
            @closePaneAndModal pane, modal
        "Cancel"    :
          cssClass  : "modal-cancel"
          title     : "Cancel"
          callback  : =>
            modal.destroy()

  closePaneAndModal: (pane, modal) ->
    @removePane pane
    modal.destroy()
