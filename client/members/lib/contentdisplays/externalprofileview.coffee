kd = require 'kd'
isMine = require 'app/util/isMine'
JView = require 'app/jview'
jspath = require 'jspath'


module.exports = class ExternalProfileView extends JView

  {warn} = kd

  constructor: (options, account) ->

    options.tagName  or= 'a'
    options.provider or= ''
    options.cssClass   = kd.utils.curry "external-profile #{options.provider}", options.cssClass
    options.attributes = href : '#'

    super options, account

    @linked        = no
    {provider}     = @getOptions()
    mainController = kd.getSingleton 'mainController'

    mainController.on "ForeignAuthSuccess.#{provider}", @bound "setLinkedState"


  viewAppended:->

    super

    @setTooltip title : "Click to link your #{@getOption 'nicename'} account"
    @setLinkedState()

  setLinkedState:->

    return  unless @parent
    account     = @parent.getData()
    {firstName} = account.profile

    {provider, nicename} = @getOptions()

    account.fetchStorage "ext|profile|#{provider}", (err, storage)=>
      return warn err  if err
      return           unless storage
      return           unless urlLocation = @getOption 'urlLocation'

      @setData storage

      @$().detach()
      @$().prependTo @parent.$('.external-profiles')
      @linked = yes
      @setClass 'linked'
      @setAttributes
        href   : jspath.getAt storage.content, urlLocation
        target : '_blank'

      @setTooltip if isMine(account)
      then title : "Go to my #{nicename} profile"
      else title : "Go to #{firstName}'s #{nicename} profile"


  click:(event)->

    return  if @linked

    {provider} = @getOptions()
    if isMine @parent.getData()
      kd.utils.stopDOMEvent event
      kd.singletons.oauthController.openPopup provider


  pistachio:->

    """
    <span class="icon"></span>
    """
