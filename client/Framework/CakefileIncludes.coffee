Includes =
  changedAt                   : Math.round(Date.now()/1000)
  order                       :
    Cake                      :
      Main                    :
        includes              : "./CakefileIncludes.coffee"

    Client:
      Framework               :
        # core
        __utils               : "./core/utils.coffee"
        KD                    : "./core/KD.coffee"
        KDEventEmitter        : "./core/KDEventEmitter.coffee"
        KDObject              : "./core/KDObject.coffee"
        KDView                : "./core/KDView.coffee"
        JView                 : "./core/JView.coffee"
        KDCustomHTMLView      : "./core/KDCustomHTMLView.coffee"
        KDScrollView          : "./core/KDScrollView.coffee"
        KDRouter              : "./core/KDRouter.coffee"

        KDController          : "./core/KDController.coffee"
        KDWindowController    : "./core/KDWindowController.coffee"
        KDViewController      : "./core/KDViewController.coffee"

        # components

        # image
        KDImage               : "./components/image/KDImage.coffee"

        # split
        KDSplitView           : "./components/split/splitview.coffee"
        KDSplitResizer        : "./components/split/splitresizer.coffee"
        KDSplitPanel          : "./components/split/splitpanel.coffee"

        # header
        KDHeaderView          : "./components/header/KDHeaderView.coffee"

        # loader
        KDLoaderView          : "./components/loader/KDLoaderView.coffee"

        #list
        KDListViewController  : "./components/list/KDListViewController.coffee"
        KDListView            : "./components/list/KDListView.coffee"
        KDListItemView        : "./components/list/KDListItemView.coffee"

        #tree
        KDTreeViewController  : "./components/tree/KDTreeViewController.coffee"
        KDTreeView            : "./components/tree/KDTreeView.coffee"
        KDTreeItemView        : "./components/tree/KDTreeItemView.coffee"
        JTreeViewController   : "./components/tree/treeviewcontroller.coffee"
        JTreeView             : "./components/tree/treeview.coffee"
        JTreeItemView         : "./components/tree/treeitemview.coffee"

        #tabs
        KDTabViewController   : "./components/tabs/KDTabViewController.coffee"
        KDTabView             : "./components/tabs/KDTabView.coffee"
        KDTabPaneView         : "./components/tabs/KDTabPaneView.coffee"
        KDTabViewWithForms    : "./components/tabs/KDTabViewWithForms.coffee"

        # menus
        KDContextMenu         : "./components/menus/KDContextMenu.coffee"

        # menus
        JContextMenu          : "./components/contextmenu/contextmenu.coffee"
        JContextMenuTreeViewC : "./components/contextmenu/contextmenutreeviewcontroller.coffee"
        JContextMenuTreeView  : "./components/contextmenu/contextmenutreeview.coffee"
        JContextMenuItem      : "./components/contextmenu/contextmenuitem.coffee"

        # inputs
        KDInputValidator      : "./components/inputs/KDInputValidator.coffee"
        KDLabelView           : "./components/inputs/KDLabelView.coffee"
        KDInputView           : "./components/inputs/KDInputView.coffee"
        KDHitEnterInputView   : "./components/inputs/KDHitEnterInputView.coffee"
        KDInputRadioGroup     : "./components/inputs/KDInputRadioGroup.coffee"
        KDInputSwitch         : "./components/inputs/KDInputSwitch.coffee"
        KDOnOffSwitch         : "./components/inputs/KDOnOffSwitch.coffee"
        KDSelectBox           : "./components/inputs/KDSelectBox.coffee"
        KDSliderView          : "./components/inputs/KDSliderView.coffee"
        KDWmdInput            : "./components/inputs/KDWmdInput.coffee"
        KDTokenizedMenu       : "./components/inputs/tokenizedmenu.coffee"
        KDTokenizedInput      : "./components/inputs/tokenizedinput.coffee"

        # upload
        KDFileUploadView      : "./components/upload/KDFileUploadView.coffee"
        KDImageUploadView     : "./components/upload/KDImageUploadView.coffee"

        # buttons
        KDButtonView          : "./components/buttons/KDButtonView.coffee"
        KDButtonViewWithMenu  : "./components/buttons/KDButtonViewWithMenu.coffee"
        KDButtonMenu          : "./components/buttons/KDButtonMenu.coffee"
        KDButtonGroupView     : "./components/buttons/KDButtonGroupView.coffee"

        # forms
        KDFormView            : "./components/forms/KDFormView.coffee"
        KDFormViewWithFields  : "./components/forms/KDFormViewWithFields.coffee"

        # modal
        KDModalController     : "./components/modals/KDModalController.coffee"
        KDModalView           : "./components/modals/KDModalView.coffee"
        KDModalViewLoad       : "./components/modals/KDModalViewLoad.coffee"
        KDBlockingModalView   : "./components/modals/KDBlockingModalView.coffee"
        KDModalViewWithForms  : "./components/modals/KDModalViewWithForms.coffee"

        # notification
        KDNotificationView    : "./components/notifications/KDNotificationView.coffee"

        # dialog
        KDDialogView          : "./components/dialog/KDDialogView.coffee"

        #tooltip
        KDToolTipMenu         : "./components/tooltip/KDToolTipMenu.coffee"

        # autocomplete
        KDAutoCompleteC       : "./components/autocomplete/autocompletecontroller.coffee"
        KDAutoComplete        : "./components/autocomplete/autocomplete.coffee"
        KDAutoCompleteList    : "./components/autocomplete/autocompletelist.coffee"
        KDAutoCompleteListItem: "./components/autocomplete/autocompletelistitem.coffee"
        KDAutoCompletedItems  : "./components/autocomplete/autocompleteditems.coffee"
        KDAutoCompleteMisc    : "./components/autocomplete/autocompletemisc.coffee"


      Dependencies            :

        pistachio             : "../../pistachio/browser/pistachio.js"

        # these are libraries, but adding it here so they are minified properly
        # minifying jquery breaks the code.
        jqueryHash            : "../libs/jquery-hashchange.js"
        jqueryTimeAgo         : "../libs/jquery-timeago.js"
        dateFormat            : "../libs/date.format.js"
        jqueryCookie          : "../libs/jquery.cookie.js"
        md5                   : "../libs/md5-min.js"
        # jqueryFieldSelect     : "../libs/jquery.fieldselection.js"

        bootstrapTwipsy       : "../libs/bootstrap-twipsy.js"
        jTipsy                : "../libs/jquery.tipsy.js"
        async                 : "../libs/async.js"
        jMouseWheel           : "../libs/jquery.mousewheel.js"
        jMouseWheelIntent     : "../libs/mwheelIntent.js"
        inflector             : "../libs/inflector.js"
        canvasLoader          : "../libs/canvas-loader.js"

        jspath                : "../app/Helpers/jspath.coffee"

      Libraries :

        html_encoder          : "../libs/encode.js"
        docwriteNoop          : "../libs/docwritenoop.js"
        sha1                  : "../libs/sha1.encapsulated.coffee"

      StylusFiles  :

        kdfn                  : "./themes/default/kdfn.styl"


        kd                    : "./themes/default/kd.styl"
        kdInput               : "./themes/default/kd.input.styl"
        kdTreeView            : "./themes/default/kd.treeview.styl"
        kdContextMenu         : "./themes/default/kd.contextmenu.styl"
        kdDialog              : "./themes/default/kd.dialog.styl"
        kdButtons             : "./themes/default/kd.buttons.styl"
        kdScrollView          : "./themes/default/kd.scrollview.styl"
        kdModalView           : "./themes/default/kd.modal.styl"
        kdFormView            : "./themes/default/kd.form.styl"

      CssFiles  :
        reset                 : "../css/style.css"
        tipsy                 : "../css/tipsy.css"

module.exports = Includes
