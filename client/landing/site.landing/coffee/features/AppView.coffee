module.exports = class FeaturesView extends KDView

  constructor:(options = {}, data)->

    super options, data

    @setPartial @partial()


  partial: ->

    """
    <h1>Features</h1>
    """


