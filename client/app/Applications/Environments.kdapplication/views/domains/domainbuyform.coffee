class DomainBuyForm extends CommonDomainCreateForm

  constructor:(options = {}, data)->
    super
      placeholder : "Type your awesome domain..."
    , data

    @availableDomainsList = new KDListViewController
      itemClass : DomainBuyItem

    @domainListView = @availableDomainsList.getView()
                      .setClass 'domain-list'

    listView = @availableDomainsList.getListView()
    listView.on 'BuyButtonClicked', (item)->
      {price, domain} = item.getData()
      year  =  item.yearBox.getValue()
      price = (year * price).toFixed 2
      modal = new DomainBuyModal
        domain      : domain
        confirmForm : new DomainBuyConfirmForm { domain, year, price }

      modal.on 'PaymentConfirmed', (data) ->
        data; debugger

  viewAppended:->
    tldList = []
    KD.remote.api.JDomain.getTldList (tlds)=>
      for tld in tlds
        tldList.push {title:".#{tld}", value: tld}
      @inputs.domains.setSelectOptions tldList
    @addSubView @domainListView

  setAvailableDomainsData:(domains)->
    @availableDomainsList.replaceAllItems domains
    @utils.defer => @domainListView.setClass 'in'