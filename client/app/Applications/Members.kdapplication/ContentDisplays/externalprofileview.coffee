class ExternalProfileView extends JView

  constructor: (options, account) ->

    options.tagName  or= 'a'
    options.type     or= 'no type given'
    options.cssClass   = KD.utils.curry "external-profile #{options.type}", options.cssClass
    options.attributes = href : '#'

    super options, account

    @linked        = no
    provider       = @getOption 'type'
    mainController = KD.getSingleton 'mainController'

    mainController.on "ForeignAuthSuccess.#{provider}", @bound "setLinkedState"


  viewAppended:->

    super

    @setTooltip title : "Click to bind your #{@getOption 'nicename'} account"
    @setLinkedState()

  setLinkedState:->

    return unless @parent
    account  = @parent.getData()
    provider = @getOption 'type'

    account.fetchStorage "ext|profile|#{provider}", (err, storage)=>
      return warn err  if err
      return           unless storage
      @setData storage

      @$().detach()
      @$().prependTo @parent.$('.external-profiles')
      @linked = yes
      @setClass 'linked'
      @setAttributes
        href   : JsPath.getAt @getData().content, @getOption('urlLocation')
        target : '_blank'

    account = @parent.getData()
    {firstName} = account.profile
    provider    = @getOption 'nicename'

    if KD.isMine account
      @setTooltip title : "Go to my #{provider} profile"
    else
      @setTooltip title : "Go to #{firstName}'s #{provider} profile"


  click:(event)->

    if @linked
      log 'send him to external profile', @getData()
    else
      {type} = @getOptions()
      if KD.isMine @parent.getData()
        KD.utils.stopDOMEvent event
        KD.singletons.oauthController.openPopup type


  pistachio:->

    """
    <span class="icon"></span>
    """