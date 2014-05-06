class FeederTabView extends KDTabView

  constructor:(options = {}, data)->

    options.cssClass or= "feeder-tabs"

    super options, data

    @unsetClass "kdscrollview"
