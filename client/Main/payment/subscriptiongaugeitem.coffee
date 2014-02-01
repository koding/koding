class SubscriptionGaugeItem extends KDListItemView

  constructor: (options = {}, data) ->

    options.type = KD.utils.slugify data.component.title

    super options, data

    @progressBar  = new KDProgressBarView
      determinate : yes
      initial     : data.usageRatio * 100

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    {label{ #(component.title)}}
    {{> @progressBar}}
    """