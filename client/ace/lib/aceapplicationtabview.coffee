kd = require 'kd'
KDModalView = kd.ModalView
KDTabView = kd.TabView
ApplicationTabView = require 'app/commonviews/applicationview/applicationtabview'


module.exports = class AceApplicationTabView extends ApplicationTabView

  removePane_: KDTabView::removePane

  removePane: (pane, shouldDetach, quiet = no) ->
    { aceView } = pane.getOptions()

    return  @removePane_ pane, shouldDetach  if quiet or not aceView

    { ace } = aceView
    file    = ace.getData()

    return @removePane_ pane, shouldDetach  unless ace.isContentChanged()

    modal = new KDModalView
      width         : 620
      cssClass      : 'modal-with-text'
      title         : 'Do you want to save your changes?'
      content       : "<p>Your changes will be lost if you don't save them.</p>"
      overlay       : yes
      buttons       :
        'SaveClose' :
          cssClass  : 'solid green medium'
          title     : 'Save and Close'
          callback  : =>
            if file.path.indexOf('localfile:') is 0
              file.once 'fs.saveAs.finished', => @removePane_ pane
              @willClose = yes
              ace.requestSaveAs()
              modal.destroy()
            else
              ace.requestSave()
              @closePaneAndModal pane, modal
        'DontSave'  :
          cssClass  : 'solid red medium'
          title     : "Don't Save"
          callback  : =>
            @closePaneAndModal pane, modal
        'Cancel'   :
          cssClass  : 'solid light-gray medium'
          title     : 'Cancel'
          callback  : ->
            modal.destroy()

  closePaneAndModal: (pane, modal) ->
    @removePane_ pane
    modal.destroy()
