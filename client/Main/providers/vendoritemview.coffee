class VendorItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass = "#{data.name}"
    super options, data

  viewAppended: JView::viewAppended

  pistachio:-> ""
