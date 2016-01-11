kd = require 'kd'
KDButtonView = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView
KDFormView = kd.FormView
KDInputView = kd.InputView
KDView = kd.View


module.exports = class AccountEditorExtensionTagger extends KDFormView
  viewAppended:->
    # FIXME : SET AUTOCOMPLETE VIEW AS IN MEMBERS SEARCH
    @addSubView tagInput = new KDInputView
      placeholder  : "add a file type... (not available on Private Beta)"
      name         : "extension-tag"

    @addSubView actions = new KDView
      cssClass : "actions-wrapper"

    actions.addSubView save = new KDButtonView
      title        : "Save"

    actions.addSubView cancel = new KDCustomHTMLView
      tagName      : "a"
      partial      : "cancel"
      cssClass     : "cancel-link"
      click        : => @emit "FormCancelled"
