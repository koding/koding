class OpenWithModal extends KDObject

  constructor: (options = {}, data)->

    super options, data

    {nodeView,apps} = @getData()
    # appsController  = KD.getSingleton "kodingAppsController"
    appManager      = KD.getSingleton "appManager"
    fileName        = FSHelper.getFileNameFromPath nodeView.getData().path
    fileExtension   = FSHelper.getFileExtension fileName

    modal = new KDModalView
      title         : "Choose application to open #{fileName}"
      cssClass      : "open-with-modal"
      overlay       : yes
      width         : 400
      buttons       :
        Open        :
          title     : "Open"
          style     : "modal-clean-green"
          callback  : =>
            appName = modal.selectedApp.getData()

            # if @alwaysOpenWith.getValue()
            #   appsController.emit "UpdateDefaultAppConfig", fileExtension, appName

            appManager.openFileWithApplication appName, nodeView.getData()
            modal.destroy()
        Cancel     :
          title    : "Cancel"
          style    : "modal-cancel"
          callback : => modal.destroy()

    # {extensionToApp} = appsController
    # supportedApps    = extensionToApp[fileExtension] or extensionToApp.txt
    supportedApps = ["Ace"]

    for appName in supportedApps
      modal.addSubView new OpenWithModalItem
        supported : yes
        delegate  : modal
      , appName

    modal.addSubView new KDView
      cssClass     : "separator"

    for own appName, manifest of apps when supportedApps.indexOf(appName) is -1
      modal.addSubView new OpenWithModalItem { delegate: modal }, manifest

    label = new KDLabelView
      title : "Always open with..."

    @alwaysOpenWith = new KDInputView
      label : label
      type  : "checkbox"

    modal.buttonHolder.addSubView @alwaysOpenWith
    modal.buttonHolder.addSubView label