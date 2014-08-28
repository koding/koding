class LoginInputViewWithLoader extends LoginInputView

  constructor:(options, data)->
    super

    @loader = new KDLoaderView
      cssClass      : "input-loader"
      size          :
        width       : 32
        height      : 32
      loaderOptions :
        color       : "#3E4F55"

    @loader.hide()

  pistachio:-> "{{> @input}}{{> @loader}}{{> @placeholder}}{{> @icon}}"
