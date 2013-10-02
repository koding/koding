module.exports = [
  # --- Libraries ---
  "libs/encode.js",
  "libs/docwritenoop.js",
  "libs/sha1.encapsulated.coffee",
  "libs/jquery-1.9.1.js",
  "libs/underscore-min.1.3.js"
  "libs/jquery.cookie.js",

  # --- Base class ---
  "Framework/core/utils.coffee",
  "Framework/core/KD.coffee",
  "Framework/core/KDEventEmitter.coffee",

  # --- Framework ---
  "libs/sockjs-0.3-patched.js",
  "libs/broker.js",
  "libs/bongo.js",

  # the bongo api (or an empty file, depending on the config)
  "../.build/api.js",

  "libs/pistachio.js",

  # TODO: reenable closure wrapping:
  # "includes/header.inc.js",
  # core
  "Framework/core/KDObject.coffee",
  "Framework/core/KDView.coffee",
  "Framework/core/KDOverlayView.coffee",
  "Framework/core/JView.coffee",
  "Framework/core/KDCustomHTMLView.coffee",
  "Framework/core/KDScrollView.coffee",
  "Framework/core/KDRouter.coffee",

  "Framework/core/KDController.coffee",
  "Framework/core/KDWindowController.coffee",
  "Framework/core/KDViewController.coffee",

  # components

  # image
  "Framework/components/image/KDImage.coffee",

  # split
  "Framework/components/split/splitview.coffee",
  "Framework/components/split/splitresizer.coffee",
  "Framework/components/split/splitpanel.coffee",
  "Framework/components/split/splitcomboview.coffee",

  # header
  "Framework/components/header/KDHeaderView.coffee",

  # loader
  "Framework/components/loader/KDLoaderView.coffee",

  #list
  "Framework/components/list/KDListViewController.coffee",
  "Framework/components/list/KDListView.coffee",
  "Framework/components/list/KDListItemView.coffee",

  #tree
  "Framework/components/tree/treeviewcontroller.coffee",
  "Framework/components/tree/treeview.coffee",
  "Framework/components/tree/treeitemview.coffee",

  #tabs
  "Framework/components/tabs/KDTabHandleView.coffee",
  "Framework/components/tabs/KDTabView.coffee",
  "Framework/components/tabs/KDTabPaneView.coffee",
  "Framework/components/tabs/KDTabViewWithForms.coffee",

  # menus
  "Framework/components/contextmenu/contextmenu.coffee",
  "Framework/components/contextmenu/contextmenutreeviewcontroller.coffee",
  "Framework/components/contextmenu/contextmenutreeview.coffee",
  "Framework/components/contextmenu/contextmenuitem.coffee",

  # dias
  "Framework/components/dia/kddiajoint.coffee",
  "Framework/components/dia/kddiaobject.coffee",
  "Framework/components/dia/kddiacontainer.coffee",
  "Framework/components/dia/kddiascene.coffee",

  # inputs
  "Framework/components/inputs/KDInputValidator.coffee",
  "Framework/components/inputs/KDLabelView.coffee",
  "Framework/components/inputs/KDInputView.coffee",
  "Framework/components/inputs/KDInputViewWithPreview.coffee",
  "Framework/components/inputs/KDHitEnterInputView.coffee",
  "Framework/components/inputs/KDInputRadioGroup.coffee",
  "Framework/components/inputs/KDInputCheckboxGroup.coffee",
  "Framework/components/inputs/KDInputSwitch.coffee",
  "Framework/components/inputs/KDOnOffSwitch.coffee",
  "Framework/components/inputs/KDMultipleChoice.coffee",
  "Framework/components/inputs/KDSelectBox.coffee",
  "Framework/components/inputs/KDSliderView.coffee",
  "Framework/components/inputs/KDWmdInput.coffee",
  "Framework/components/inputs/tokenizedmenu.coffee",
  "Framework/components/inputs/tokenizedinput.coffee",
  "Framework/components/inputs/KDContentEditableView.coffee",

  # upload
  "Framework/components/upload/KDFileUploadView.coffee",
  "Framework/components/upload/KDImageUploadView.coffee",
  "Framework/components/upload/kdmultipartuploader.coffee",

  # buttons
  "Framework/components/buttons/KDButtonView.coffee",
  "Framework/components/buttons/KDButtonViewWithMenu.coffee",
  "Framework/components/buttons/KDButtonMenu.coffee",
  "Framework/components/buttons/KDButtonGroupView.coffee",
  "Framework/components/buttons/KDToggleButton.coffee",

  # forms
  "Framework/components/forms/KDFormView.coffee",
  "Framework/components/forms/KDFormViewWithFields.coffee",

  # modal
  "Framework/components/modals/KDModalController.coffee",
  "Framework/components/modals/KDModalView.coffee",
  "Framework/components/modals/KDModalViewLoad.coffee",
  "Framework/components/modals/KDBlockingModalView.coffee",
  "Framework/components/modals/KDModalViewWithForms.coffee",
  "Framework/components/modals/KDModalViewStack.coffee",

  # notification
  "Framework/components/notifications/KDNotificationView.coffee",

  # progressbar
  "Framework/components/progressbar/KDProgressBarView.coffee",

  # sliderbar
  "Framework/components/sliderbar/KDSliderBarView.coffee",
  "Framework/components/sliderbar/KDSliderBarHandleView.coffee",

  # dialog
  "Framework/components/dialog/KDDialogView.coffee",

  #tooltip
  "Framework/components/tooltip/KDToolTipMenu.coffee",
  "Framework/components/tooltip/KDTooltip.coffee",

  # autocomplete
  "Framework/components/autocomplete/autocompletecontroller.coffee",
  "Framework/components/autocomplete/autocomplete.coffee",
  "Framework/components/autocomplete/autocompletelist.coffee",
  "Framework/components/autocomplete/autocompletelistitem.coffee",
  "Framework/components/autocomplete/multipleinputview.coffee",
  "Framework/components/autocomplete/autocompletemisc.coffee",
  "Framework/components/autocomplete/autocompleteditems.coffee",

  # time
  "Framework/components/time/timeagoview.coffee",

  # these are libraries, but adding it here so they are minified properly
  # minifying jquery breaks the code.
  "libs/jquery-timeago.js",
  "libs/date.format.js",
  "libs/jquery.getcss.js",
  "libs/mousetrap.js",
  "libs/md5-min.js",
  "libs/async.js",
  "libs/jquery.mousewheel.js",
  "libs/inflector.js",
  "libs/canvas-loader.js",
  "libs/marked.js",
  "app/Helpers/jspath.coffee",

  # --- Styles ---
  # "css/style.css",
  # "css/highlight-styles/sunburst.css",

  # "Framework/themes/default/kdfn.styl",
  # "stylus/appfn.styl",

  # "Framework/themes/default/kd.styl",
  # "Framework/themes/default/kd.input.styl",
  # "Framework/themes/default/kd.treeview.styl",
  # "Framework/themes/default/kd.contextmenu.styl",
  # "Framework/themes/default/kd.dialog.styl",
  # "Framework/themes/default/kd.buttons.styl",
  # "Framework/themes/default/kd.scrollview.styl",
  # "Framework/themes/default/kd.modal.styl",
  # "Framework/themes/default/kd.progressbar.styl",
  # "Framework/themes/default/kd.sliderbar.styl",
  # "Framework/themes/default/kd.form.styl",
  # "Framework/themes/default/kd.tooltip.styl",
  # "Framework/themes/default/kd.dia.styl",
  # "Framework/themes/default/kd.slide.styl",

]
