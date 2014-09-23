JView = require './../core/jview'

module.exports = class LoginViewInlineForm extends KDFormView

  JView.mixin @prototype

  viewAppended:->

    @setTemplate @pistachio()
    @template.update()

    @on "FormValidationFailed", => @button.hideLoader()

  pistachio:->

