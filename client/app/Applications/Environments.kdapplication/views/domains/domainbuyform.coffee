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
    listView.on 'BuyButtonClicked', (item) =>
      {price, domain} = item.getData()
      year = +item.yearBox.getValue()
      displayPrice = @utils.formatMoney year * price
      
      workflow = new PaymentWorkflow
        productForm : new DomainProductForm
        confirmForm : new DomainPaymentConfirmForm {
          domain, year, price: displayPrice
        }
      
      modal = new BuyModal
        title       : "Register <em>#{ domain }</em>"
        workflow    : workflow

      workflow.on 'DataCollected', -> debugger 
#      ({ productData, paymentMethodId }) =>
#        @buyDomain { domain, year, price, paymentMethodId, productData }

  buyDomain: (options) ->
    { JDomain } = KD.remote.api

    { price, paymentMethodId, productData: address, year, domain } = options
    
    # warning: floating point arithmetic is not associative:

    priceInCents = price * 100 # cents
    
    feeAmount = priceInCents * year

    description = 
      """
      Domain name — #{domain} — #{@utils.formatPlural year, 'year'}
      """

    options = {
      domain
      year
      address
      transaction: {
        feeAmount
        paymentMethodId
        description
      }
    }

    JDomain.registerDomain options, (err) ->
      debugger

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