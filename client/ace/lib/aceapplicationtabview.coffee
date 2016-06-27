kd = require 'kd'
KDModalView = kd.ModalView
KDTabView = kd.TabView
ApplicationTabView = require 'app/commonviews/applicationview/applicationtabview'
ContentModal = require 'app/components/contentModal'

module.exports = class AceApplicationTabView extends ApplicationTabView

  removePane_: KDTabView::removePane

  removePane: (pane, shouldDetach, quiet = no) ->
    { aceView } = pane.getOptions()

    return  @removePane_ pane, shouldDetach  if quiet or not aceView

    { ace } = aceView
    file    = ace.getData()

    return @removePane_ pane, shouldDetach  unless ace.isContentChanged()

    modal = new ContentModal
      width         : 600
      cssClass      : 'modal-with-text'
      title         : 'Do you want to save your changes?'
      content       : "<p>Your changes will be lost if you don't save them.</p>"
      overlay       : yes
      buttons       :
        'DontSave'  :
          cssClass  : 'solid cancel medium'
          title     : "Don't Save"
          callback  : =>
            @closePaneAndModal pane, modal
        'SaveClose' :
          cssClass  : 'solid medium'
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

  closePaneAndModal: (pane, modal) ->
    @removePane_ pane
    modal.destroy()
