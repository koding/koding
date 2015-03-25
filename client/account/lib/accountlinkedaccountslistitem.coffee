kd = require 'kd'
KDListItemView = kd.ListItemView
KDNotificationView = kd.NotificationView
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
KodingSwitch = require 'app/commonviews/kodingswitch'
JView = require 'app/jview'


module.exports = class AccountLinkedAccountsListItem extends KDListItemView

  JView.mixin @prototype

  notify = (message)-> new KDNotificationView title : message, type : 'mini', duration : 3000


  constructor:(options = {}, data)->

    options.tagName or= "li"
    options.type    or= "oauth"

    super options, data

    @linked    = no
    {provider} = @getData()
    @setClass provider

    @switch = new KodingSwitch
      callback: (state)=>
        @switch.setOff no
        if state then @link() else @unlink()

    mainController = kd.getSingleton "mainController"
    mainController.on "ForeignAuthSuccess.#{provider}", =>
      @linked = yes
      @switch.setOn no

  link:->

    {provider} = @getData()
    kd.singletons.oauthController.openPopup provider


  unlink:->

    {title, provider} = @getData()
    account           = whoami()
    account.unlinkOauth provider, (err)=>
      return showError err  if err
      account.unstore "ext|profile|#{provider}", (err, storage)->
        return kd.warn err  if err

      notify "Your #{title} account is now unlinked."
      @linked = no

  viewAppended:->

    JView::viewAppended.call this
    {provider} = @getData()
    whoami().fetchOAuthInfo (err, foreignAuth)=>
      @linked = foreignAuth?[provider]?
      @switch.setDefaultValue @linked

  pistachio:->

    """
    {{> @switch}}
    <div class='title'><span class='icon'></span>{cite{ #(title)}}</div>
    """

