kd               = require 'kd'
KDView           = kd.View
KDFormView       = kd.FormView
KDInputView      = kd.InputView
KDButtonView     = kd.ButtonView
KDCustomHTMLView = kd.CustomHTMLView


module.exports = class AccountEditorExtensionTagger extends KDFormView

  viewAppended: ->
    # FIXME : SET AUTOCOMPLETE VIEW AS IN MEMBERS SEARCH
    @addSubView new KDInputView
      placeholder  : 'add a file type... (not available on Private Beta)'
      name         : 'extension-tag'

    @addSubView actions = new KDView
      cssClass : 'actions-wrapper'

    actions.addSubView new KDButtonView
      title        : 'Save'

    actions.addSubView new KDCustomHTMLView
      tagName      : 'a'
      partial      : 'cancel'
      cssClass     : 'cancel-link'
      click        : => @emit 'FormCancelled'
