class ManageDomainsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'domains-view', options.cssClass

    super options, data

    {@machine} = @getOptions()

    domainSuffix = ".#{KD.nick()}.#{KD.config.userSitesDomain}"

    @addSubView @inputView = new KDView
      cssClass          : 'input-view'

    @inputView.addSubView @input = new KDHitEnterInputView
      type              : 'text'
      attributes        :
        spellcheck      : no
      callback          : => @emit 'AddDomain'

    @inputView.addSubView new KDView
      partial           : domainSuffix
      cssClass          : 'domain-suffix'

    @domainController   = new KDListViewController
      viewOptions       :
        type            : 'domain'
        wrapper         : yes
        itemClass       : DomainItem
        dataPath        : 'domain'
    , items             : ({domain} for domain in @machine.aliases)

    @addSubView @domainController.getView()
    @inputView.hide()

    @on 'AddDomain', =>

      @addDomain "#{@input.getValue()}#{domainSuffix}"
      @input.setValue ""

      @inputView.hide()
      @emit "DomainInputCancelled"


    domainList = @domainController.getListView()
    domainList.on 'DeleteDomainRequested', (item)=>
      @domainController.removeItem item


  toggleInput:->

    @inputView.toggleClass 'hidden'

    {windowController} = KD.singletons

    windowController.addLayer @input
    @input.setFocus()

    @input.off  "ReceivedClickElsewhere"
    @input.once "ReceivedClickElsewhere", (event)=>
      return  if $(event.target).hasClass 'domain-toggle'
      @emit "DomainInputCancelled"
      @inputView.hide()

  addDomain:(domain)->

    @domainController.addItem {domain}

  removeDomain:(domain)->

    @domainController.removeItem null, {domain}
