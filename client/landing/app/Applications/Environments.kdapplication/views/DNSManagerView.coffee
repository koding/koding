class DNSManagerView extends KDView

  constructor:(options={}, data)->
    data or= {}
    super options, data

    @on "domainChanged", (domainListItem)->
      @getData().domain = domainListItem.data
      @updateViewContent()

  viewAppended: JView::viewAppended

  updateViewContent:->


  pistachio:->
    """
    """