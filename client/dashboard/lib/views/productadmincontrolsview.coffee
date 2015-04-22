kd = require 'kd'
KDButtonView = kd.ButtonView
KDSelectBox = kd.SelectBox
EmbedCodeView = require './embedcodeview'
JView = require 'app/jview'


module.exports = class ProductAdminControlsView extends JView

  viewAppended: ->
    product = @getData()

    { planCode, soldAlone } = product

    @embedView = new EmbedCodeView { planCode }

    @embedButton = new KDButtonView
      title    : "View Embed Code"
      callback : =>
        if @embedView.hasClass "hidden"
          @embedView.unsetClass "hidden"
        else
          @embedView.setClass "hidden"

    @embedButton.hide()  unless soldAlone

    @clientsButton = new KDButtonView
      title    : "View buyers"
      callback : => @emit 'BuyersReportRequested', product

    @deleteButton = new KDButtonView
      title    : "Remove"
      callback : => @emit 'DeleteRequested', product

    @editButton = new KDButtonView
      title    : "Edit"
      callback : => @emit 'EditRequested', product

    @sortWeight = new KDSelectBox
      title         : "Sort weight"
      defaultValue  : "#{ product.sortWeight ? 0 }"
      selectOptions : [-100..100].map (w) ->
        title       : "#{w}"
        value       : "#{w}"
      callback      : =>
        @getData().modify { sortWeight: @sortWeight.getValue() }

    super()

  pistachio: ->
    """
    {{> @embedButton}}
    {{> @deleteButton}}
    {{> @clientsButton}}
    {{> @editButton}}
    {{> @sortWeight}}
    {{> @embedView}}
    """

