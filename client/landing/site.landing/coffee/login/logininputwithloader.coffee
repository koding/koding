kd = require 'kd'
LoginInputView = require './logininputview'

module.exports = class LoginInputViewWithLoader extends LoginInputView

  constructor: (options, data) ->
    super

    @loader = new kd.LoaderView
      cssClass      : 'input-loader'
      size          :
        width       : 32
        height      : 32
      loaderOptions :
        color       : '#3E4F55'

    @loader.hide()

  pistachio: -> '{{> @input}}{{> @loader}}{{> @placeholder}}{{> @icon}}'
