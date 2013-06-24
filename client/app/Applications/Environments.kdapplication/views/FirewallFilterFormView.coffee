class FirewallFilterFormView extends KDCustomHTMLView

  constructor:(options={}, data)->
    options.cssClass = "filter-form-view"
    super options, data

    @nameLabel        = new KDLabelView
      title           : "Filter Name:"

    @filterLabel      = new KDLabelView
      title           : "Match:"

    @filterNameInput  = new KDInputView
      label           : @nameLabel
      tooltip         :
        title         : "Enter a name for the filter."
        placement     : "right"

    @filterInput      = new KDInputView
      label           : @filterLabel
      tooltip         :
        title         : "You can enter IP, IP Range or a country name. (ie: 192.168.1.1/24 or China)"
        placement     : "right"

    @addButton = new KDButtonView
      title    : "Add"
      callback : @bound "updateFilters"

  updateFilters:->
    filterType  = if @filterInput.getValue().match /[0-9+]/ then "ip" else "country"
    filterName  = @filterNameInput.getValue()
    filterMatch = @filterInput.getValue()
    delegate    = @getDelegate()

    KD.remote.api.JProxyFilter.createFilter
      name  : filterName
      type  : filterType
      match : filterMatch
    , (err, filter)->
      unless err
        delegate.emit "newFilterCreated", {name:filterName, match:filterMatch}
        return

      return new KDNotificationView
        title : "An error occured while performing your action. Please try again."
        type  : "top"


  viewAppended: JView::viewAppended

  pistachio:->
    """
      <section class="clearfix">
        <div class="input-container">
          {{> @nameLabel}}
          {{> @filterNameInput }}
        </div>
        <div class="input-container">
          {{> @filterLabel}}
          {{> @filterInput }}
        </div>
        <div class="input-container">
          {{> @addButton }}
        </div>
      </section>
    """