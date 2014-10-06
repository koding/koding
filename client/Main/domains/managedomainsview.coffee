class ManageDomainsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'domains-view', options.cssClass

    super options, data

    @addSubView new KDHitEnterInputView
      type       : 'text'
      attributes : spellcheck: false
      callback   : => @emit 'AddDomain'

    @domainController   = new KDListViewController
      viewOptions       :
        type            : 'domain'
        wrapper         : yes
        itemClass       : DomainItem
    , items             : [
      {domain: "google.com"}
      {domain: "yahoo.com"}
    ]

    @addSubView @domainList = @domainController.getView()
