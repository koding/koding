class ProviderItemView extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->

    options.cssClass = "#{data.name}"
    super options, data

  pistachio:-> ""
