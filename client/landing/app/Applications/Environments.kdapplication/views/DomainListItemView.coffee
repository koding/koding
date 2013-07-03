class DomainListItemView extends KDListItemView

  constructor: (options={}, data)->
    options.tagName  = "li"
    options.cssClass = 'domain-item'
    super options, data
    {createdAt} = @getData()
    @createdAgo  = new KDTimeAgoView {}, createdAt

  click: (event)->
    listView = @getDelegate()
    listView.emit "domainsListItemViewClicked", this

  contextMenu:(event)->
    contextMenu = new JContextMenu
      menuWidth   : 200
      delegate    : this
      x           : @getX() + 26
      y           : @getY() - 19
      arrow       :
        placement : "left"
        margin    : 19
      lazyLoad    : yes
    ,
      'Bind to VM'    :
        callback      : -> @destroy()
      'Delete Domain' :
        callback      : -> @destroy()
        separator     : yes

  viewAppended: JView::viewAppended

  pistachio:->
    {domain, regYears, createdAt, hostnameAlias} = @getData()
    regYearsText = ""

    if regYears > 0
      yearText = if regYears > 1 then "years" else "year"
      regYearsText = "Registered for #{regYears} #{yearText}, "

    """
      {.domain-title{ #(domain)}}
      <div class="domain-detail">#{regYearsText}{{> @createdAgo}}</div>
    """
