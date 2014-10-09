class ManageDomainsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'domains-view', options.cssClass

    super options, data

    {@machine} = @getOptions()

    @domainSuffix = ".#{KD.nick()}.#{KD.config.userSitesDomain}"

    @addSubView @inputView = new KDView
      cssClass          : 'input-view'

    @inputView.addSubView @input = new KDHitEnterInputView
      type              : 'text'
      attributes        :
        spellcheck      : no
      callback          : @bound 'addDomain'

    @inputView.addSubView new KDView
      partial           : @domainSuffix
      cssClass          : 'domain-suffix'

    topDomain = "#{KD.nick()}.#{KD.config.userSitesDomain}"

    @domainController   = new KDListViewController
      viewOptions       :
        type            : 'domain'
        wrapper         : yes
        itemClass       : DomainItem
        itemOptions     :
          machineId     : @machine._id

    @addSubView @domainController.getView()
    @inputView.hide()




    @addSubView @loader = new KDLoaderView
      cssClass      : 'in-progress'
      size          :
        width       : 14
        height      : 14
      loaderOptions :
        color       : '#FFFFFF'
      showLoader    : yes

    @listDomains()


  listDomains: (reset = no)->

    {computeController} = KD.singletons
    computeController.domains = []  if reset
    computeController.fetchDomains (err, domains = [])=>
      warn err  if err?
      @domainController.replaceAllItems domains
      @loader.hide()


  addDomain:->

    {computeController} = KD.singletons

    domain = "#{Encoder.XSSEncode @input.getValue().trim()}#{@domainSuffix}"
    machineId = @machine._id

    @loader.show()
    @warning.hide()
    @input.makeDisabled()

    computeController.kloud

      .addDomain {domainName: domain, machineId}

      .then =>
        @domainController.addItem { domain, machineId }
        computeController.domains = []

        @input.setValue ""
        @inputView.hide()
        @emit "DomainInputCancelled"

      .catch (err)=>
        warn "Failed to create domain:", err
        @warning.setTooltip title: err.message
        @warning.show()
        @input.setFocus()

      .finally =>
        @input.makeEnabled()
        @loader.hide()


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
