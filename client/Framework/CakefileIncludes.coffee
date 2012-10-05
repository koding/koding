Includes =
  changedAt                   : Math.round(Date.now()/1000)
  order                       :
    Cake                      :
      Main                    :
        includes              : "./CakefileIncludes.coffee"

    Client:
      Framework               :
        # core
        __utils               : "./client/Framework/core/utils.coffee"
        KD                    : "./client/Framework/core/KD.coffee"
        KDEventEmitter        : "./client/Framework/core/KDEventEmitter.coffee"
        KDObject              : "./client/Framework/core/KDObject.coffee"
        KDView                : "./client/Framework/core/KDView.coffee"
        JView                 : "./client/Framework/core/JView.coffee"
        KDCustomHTMLView      : "./client/Framework/core/KDCustomHTMLView.coffee"
        KDScrollView          : "./client/Framework/core/KDScrollView.coffee"
        KDRouter              : "./client/Framework/core/KDRouter.coffee"

        KDController          : "./client/Framework/core/KDController.coffee"
        KDWindowController    : "./client/Framework/core/KDWindowController.coffee"
        KDViewController      : "./client/Framework/core/KDViewController.coffee"

        # components

        # image
        KDImage               : "./client/Framework/components/image/KDImage.coffee"

        # split
        KDSplitView           : "./client/Framework/components/split/splitview.coffee"
        KDSplitResizer        : "./client/Framework/components/split/splitresizer.coffee"
        KDSplitPanel          : "./client/Framework/components/split/splitpanel.coffee"

        # header
        KDHeaderView          : "./client/Framework/components/header/KDHeaderView.coffee"

        # loader
        KDLoaderView          : "./client/Framework/components/loader/KDLoaderView.coffee"

        #list
        KDListViewController  : "./client/Framework/components/list/KDListViewController.coffee"
        KDListView            : "./client/Framework/components/list/KDListView.coffee"
        KDListItemView        : "./client/Framework/components/list/KDListItemView.coffee"

        #tree
        KDTreeViewController  : "./client/Framework/components/tree/KDTreeViewController.coffee"
        KDTreeView            : "./client/Framework/components/tree/KDTreeView.coffee"
        KDTreeItemView        : "./client/Framework/components/tree/KDTreeItemView.coffee"
        JTreeViewController   : "./client/Framework/components/tree/treeviewcontroller.coffee"
        JTreeView             : "./client/Framework/components/tree/treeview.coffee"
        JTreeItemView         : "./client/Framework/components/tree/treeitemview.coffee"

        #tabs
        KDTabViewController   : "./client/Framework/components/tabs/KDTabViewController.coffee"
        KDTabView             : "./client/Framework/components/tabs/KDTabView.coffee"
        KDTabPaneView         : "./client/Framework/components/tabs/KDTabPaneView.coffee"
        KDTabViewWithForms    : "./client/Framework/components/tabs/KDTabViewWithForms.coffee"

        # menus
        KDContextMenu         : "./client/Framework/components/menus/KDContextMenu.coffee"

        # menus
        JContextMenu          : "./client/Framework/components/contextmenu/contextmenu.coffee"
        JContextMenuTreeViewC : "./client/Framework/components/contextmenu/contextmenutreeviewcontroller.coffee"
        JContextMenuTreeView  : "./client/Framework/components/contextmenu/contextmenutreeview.coffee"
        JContextMenuItem      : "./client/Framework/components/contextmenu/contextmenuitem.coffee"

        # inputs
        KDInputValidator      : "./client/Framework/components/inputs/KDInputValidator.coffee"
        KDLabelView           : "./client/Framework/components/inputs/KDLabelView.coffee"
        KDInputView           : "./client/Framework/components/inputs/KDInputView.coffee"
        KDHitEnterInputView   : "./client/Framework/components/inputs/KDHitEnterInputView.coffee"
        KDInputRadioGroup     : "./client/Framework/components/inputs/KDInputRadioGroup.coffee"
        KDInputSwitch         : "./client/Framework/components/inputs/KDInputSwitch.coffee"
        KDOnOffSwitch         : "./client/Framework/components/inputs/KDOnOffSwitch.coffee"
        KDSelectBox           : "./client/Framework/components/inputs/KDSelectBox.coffee"
        KDSliderView          : "./client/Framework/components/inputs/KDSliderView.coffee"
        KDWmdInput            : "./client/Framework/components/inputs/KDWmdInput.coffee"
        KDTokenizedMenu       : "./client/Framework/components/inputs/tokenizedmenu.coffee"
        KDTokenizedInput      : "./client/Framework/components/inputs/tokenizedinput.coffee"

        # upload
        KDFileUploadView    : "./client/Framework/components/upload/KDFileUploadView.coffee"
        KDImageUploadView   : "./client/Framework/components/upload/KDImageUploadView.coffee"

        # buttons
        KDButtonView          : "./client/Framework/components/buttons/KDButtonView.coffee"
        KDButtonViewWithMenu  : "./client/Framework/components/buttons/KDButtonViewWithMenu.coffee"
        KDButtonMenu          : "./client/Framework/components/buttons/KDButtonMenu.coffee"
        KDButtonGroupView     : "./client/Framework/components/buttons/KDButtonGroupView.coffee"

        # forms
        KDFormView            : "./client/Framework/components/forms/KDFormView.coffee"
        KDFormViewWithFields  : "./client/Framework/components/forms/KDFormViewWithFields.coffee"

        # modal
        KDModalController     : "./client/Framework/components/modals/KDModalController.coffee"
        KDModalView           : "./client/Framework/components/modals/KDModalView.coffee"
        KDModalViewLoad       : "./client/Framework/components/modals/KDModalViewLoad.coffee"
        KDBlockingModalView   : "./client/Framework/components/modals/KDBlockingModalView.coffee"
        KDModalViewWithForms  : "./client/Framework/components/modals/KDModalViewWithForms.coffee"

        # notification
        KDNotificationView    : "./client/Framework/components/notifications/KDNotificationView.coffee"

        # dialog
        KDDialogView          : "./client/Framework/components/dialog/KDDialogView.coffee"

        #tooltip
        KDToolTipMenu         : "./client/Framework/components/tooltip/KDToolTipMenu.coffee"

        # autocomplete
        KDAutoCompleteC       : "./client/Framework/components/autocomplete/autocompletecontroller.coffee"
        KDAutoComplete        : "./client/Framework/components/autocomplete/autocomplete.coffee"
        KDAutoCompleteList    : "./client/Framework/components/autocomplete/autocompletelist.coffee"
        KDAutoCompleteListItem: "./client/Framework/components/autocomplete/autocompletelistitem.coffee"
        KDAutoCompletedItems  : "./client/Framework/components/autocomplete/autocompleteditems.coffee"
        KDAutoCompleteMisc    : "./client/Framework/components/autocomplete/autocompletemisc.coffee"


      Dependencies            :

        pistachio             : "./node_modules/pistachio/browser/pistachio.js"

        # these are libraries, but adding it here so they are minified properly
        # minifying jquery breaks the code.
        jqueryHash            : "./client/libs/jquery-hashchange.js"
        jqueryTimeAgo         : "./client/libs/jquery-timeago.js"
        dateFormat            : "./client/libs/date.format.js"
        jqueryCookie          : "./client/libs/jquery.cookie.js"
        md5                   : "./client/libs/md5-min.js"
        # jqueryFieldSelect     : "./client/libs/jquery.fieldselection.js"

        bootstrapTwipsy       : "./client/libs/bootstrap-twipsy.js"
        jTipsy                : "./client/libs/jquery.tipsy.js"
        async                 : "./client/libs/async.js"
        jMouseWheel           : "./client/libs/jquery.mousewheel.js"
        jMouseWheelIntent     : "./client/libs/mwheelIntent.js"
        inflector             : "./client/libs/inflector.js"
        canvasLoader          : "./client/libs/canvas-loader.js"

        jspath             : "./client/app/Helpers/jspath.coffee"

      Libraries :

        html_encoder      : "./client/libs/encode.js"
        docwriteNoop      : "./client/libs/docwritenoop.js"
        sha1              : "./client/libs/sha1.encapsulated.coffee"

      StylusFiles  :

        kdfn                : "./client/Framework/themes/default/kdfn.styl"
        appfn               : "./client/stylus/appfn.styl"


        kd                  : "./client/Framework/themes/default/kd.styl"
        kdInput             : "./client/Framework/themes/default/kd.input.styl"
        kdTreeView          : "./client/Framework/themes/default/kd.treeview.styl"
        kdContextMenu       : "./client/Framework/themes/default/kd.contextmenu.styl"
        kdDialog            : "./client/Framework/themes/default/kd.dialog.styl"
        kdButtons           : "./client/Framework/themes/default/kd.buttons.styl"
        kdScrollView        : "./client/Framework/themes/default/kd.scrollview.styl"
        kdModalView         : "./client/Framework/themes/default/kd.modal.styl"
        kdFormView          : "./client/Framework/themes/default/kd.form.styl"

      CssFiles  :
        reset               : "./client/css/style.css"
        tipsy               : "./client/css/tipsy.css"

module.exports = Includes
