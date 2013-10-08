module.exports = [

  # --- 3rd Party Libraries ---
  "libs/docwritenoop.js",
  "libs/encode.js",

  ## JQuery
  "libs/jquery-1.9.1.js",
  "libs/underscore-min.1.3.js"
  "libs/jquery.cookie.js",
  "libs/jquery-timeago.js",
  "libs/jquery.mousewheel.js",

  ## Helpers
  "libs/date.format.js",
  "libs/highlight.pack.js"
  "libs/inflector.js",
  "libs/canvas-loader.js",
  "libs/mousetrap.js"
  "libs/marked.js",
  "libs/jspath.js",

  ## Pistachio Compiler
  "libs/pistachio.js",

  # --- Base class ---
  "core/utils.coffee",
  "core/KD.coffee",
  "core/KDEventEmitter.coffee",

  # # --- Framework ---

  # core
  "core/KDObject.coffee",
  "core/KDView.coffee",
  "core/KDOverlayView.coffee",
  "core/JView.coffee",
  "core/KDCustomHTMLView.coffee",
  "core/KDScrollView.coffee",
  "core/KDRouter.coffee",
  "core/KDController.coffee",
  "core/KDWindowController.coffee",
  "core/KDViewController.coffee",

  # components

  # image
  "components/image/KDImage.coffee",

  # split
  "components/split/splitview.coffee",
  "components/split/splitresizer.coffee",
  "components/split/splitpanel.coffee",
  "components/split/splitcomboview.coffee",

  # header
  "components/header/KDHeaderView.coffee",

  # loader
  "components/loader/KDLoaderView.coffee",

  #list
  "components/list/KDListViewController.coffee",
  "components/list/KDListView.coffee",
  "components/list/KDListItemView.coffee",

  #tree
  "components/tree/treeviewcontroller.coffee",
  "components/tree/treeview.coffee",
  "components/tree/treeitemview.coffee",

  #tabs
  "components/tabs/KDTabHandleView.coffee",
  "components/tabs/KDTabView.coffee",
  "components/tabs/KDTabPaneView.coffee",
  "components/tabs/KDTabViewWithForms.coffee",

  # menus
  "components/contextmenu/contextmenu.coffee",
  "components/contextmenu/contextmenutreeviewcontroller.coffee",
  "components/contextmenu/contextmenutreeview.coffee",
  "components/contextmenu/contextmenuitem.coffee",

  # dias
  "components/dia/kddiajoint.coffee",
  "components/dia/kddiaobject.coffee",
  "components/dia/kddiacontainer.coffee",
  "components/dia/kddiascene.coffee",

  # inputs
  "components/inputs/KDInputValidator.coffee",
  "components/inputs/KDLabelView.coffee",
  "components/inputs/KDInputView.coffee",
  "components/inputs/KDInputViewWithPreview.coffee",
  "components/inputs/KDHitEnterInputView.coffee",
  "components/inputs/KDInputRadioGroup.coffee",
  "components/inputs/KDInputCheckboxGroup.coffee",
  "components/inputs/KDInputSwitch.coffee",
  "components/inputs/KDOnOffSwitch.coffee",
  "components/inputs/KDMultipleChoice.coffee",
  "components/inputs/KDSelectBox.coffee",
  "components/inputs/KDSliderView.coffee",
  "components/inputs/KDWmdInput.coffee",
  "components/inputs/tokenizedmenu.coffee",
  "components/inputs/tokenizedinput.coffee",
  "components/inputs/KDContentEditableView.coffee",

  # upload
  "components/upload/KDFileUploadView.coffee",
  "components/upload/KDImageUploadView.coffee",
  "components/upload/kdmultipartuploader.coffee",

  # buttons
  "components/buttons/KDButtonView.coffee",
  "components/buttons/KDButtonViewWithMenu.coffee",
  "components/buttons/KDButtonMenu.coffee",
  "components/buttons/KDButtonGroupView.coffee",
  "components/buttons/KDToggleButton.coffee",

  # forms
  "components/forms/KDFormView.coffee",
  "components/forms/KDFormViewWithFields.coffee",

  # modal
  "components/modals/KDModalController.coffee",
  "components/modals/KDModalView.coffee",
  "components/modals/KDModalViewLoad.coffee",
  "components/modals/KDBlockingModalView.coffee",
  "components/modals/KDModalViewWithForms.coffee",
  "components/modals/KDModalViewStack.coffee",

  # notification
  "components/notifications/KDNotificationView.coffee",

  # progressbar
  "components/progressbar/KDProgressBarView.coffee",

  # sliderbar
  "components/sliderbar/KDSliderBarView.coffee",
  "components/sliderbar/KDSliderBarHandleView.coffee",

  # dialog
  "components/dialog/KDDialogView.coffee",

  #tooltip
  "components/tooltip/KDToolTipMenu.coffee",
  "components/tooltip/KDTooltip.coffee",

  # autocomplete
  "components/autocomplete/autocompletecontroller.coffee",
  "components/autocomplete/autocomplete.coffee",
  "components/autocomplete/autocompletelist.coffee",
  "components/autocomplete/autocompletelistitem.coffee",
  "components/autocomplete/multipleinputview.coffee",
  "components/autocomplete/autocompletemisc.coffee",
  "components/autocomplete/autocompleteditems.coffee",

  # time
  "components/time/timeagoview.coffee",

  # Framework Init Script
  "init.coffee",

  # --- Styles ---
  "themes/default/style.css",

  # Style functions ---
  "themes/default/kdfn.styl",

  # Default Theme
  "themes/default/kd.styl",
  "themes/default/kd.input.styl",
  "themes/default/kd.treeview.styl",
  "themes/default/kd.contextmenu.styl",
  "themes/default/kd.dialog.styl",
  "themes/default/kd.buttons.styl",
  "themes/default/kd.scrollview.styl",
  "themes/default/kd.modal.styl",
  "themes/default/kd.progressbar.styl",
  "themes/default/kd.sliderbar.styl",
  "themes/default/kd.form.styl",
  "themes/default/kd.tooltip.styl",
  "themes/default/kd.dia.styl",

]
