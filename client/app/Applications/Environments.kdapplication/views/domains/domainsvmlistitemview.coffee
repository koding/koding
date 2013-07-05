class DomainVMListItemView extends KDListItemView
  constructor:(options={}, data)->
    options.type = 'domain-vm'
    super options, data
    @loader = new KDLoaderView
      size          :
        width       : 30
      loaderOptions :
        color       : '#ffffff'
    @loader.hide()

  viewAppended: JView::viewAppended

  hideLoader:->
    @loader.hide()
    @$('section').removeClass 'hidden'

  showLoader:->
    @loader.show()
    @$('section').addClass 'hidden'

  click:->
    @showLoader()
    list   = @getDelegate()
    domain = list.getData()
    list.emit "VMItemClicked", this


  pistachio:->
    """
    {{> @loader}}
    <section>
    <span class="vm-icon fl"></span>
    {.vm-name.right-overflow{ #(hostnameAlias) }}
    </section>
    """
