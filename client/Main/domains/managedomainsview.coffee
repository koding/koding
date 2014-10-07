class ManageDomainsView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'domains-view', options.cssClass

    super options, data

    {@machine} = @getOptions()

    @addSubView @input  = new KDHitEnterInputView
      type              : 'text'
      attributes        : spellcheck: false
      callback          : => @emit 'AddDomain'


    @domainController   = new KDListViewController
      viewOptions       :
        type            : 'domain'
        wrapper         : yes
        itemClass       : DomainItem
    , items             : ({domain} for domain in @machine.aliases)

    @addSubView @domainList = @domainController.getView()
    @input.hide()