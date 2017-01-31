kd               = require 'kd'
JView            = require 'app/jview'
KDCustomHTMLView = kd.CustomHTMLView
globals          = require 'globals'
CustomLinkView   = require 'app/customlinkview'
whoami           = require 'app/util/whoami'

module.exports = class AccountCredentialListItem extends kd.ListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'credential-item clearfix', options.cssClass

    super options, data

    delegate            = @getDelegate()
    { providers }       = globals.config
    { owner, provider } = @getData()

    @providerTag = new KDCustomHTMLView
      cssClass : 'tag'
      partial  : provider

    @providerTag.setCss 'background-color', providers[provider].color

    @credentialLinks = new KDCustomHTMLView
      cssClass : 'HomeAppView--credential-links'

    @credentialLinks.addSubView new CustomLinkView
      title    : 'REMOVE'
      item     : this
      cssClass : 'HomeAppView--link'
      click    : => delegate.emit 'ItemAction', { action : 'RemoveItem', item : this }

    if provider isnt 'aws' or @getData().fields?
      @credentialLinks.addSubView new CustomLinkView
        title    : 'EDIT'
        item     : this
        cssClass : 'HomeAppView--link'
        click    : => delegate.emit 'ItemAction', { action : 'EditItem', item : this }

    if owner
      @credentialLinks.addSubView new CustomLinkView
        title    : 'SHOW'
        item     : this
        cssClass : 'HomeAppView--link primary'
        click    : =>
          delegate.emit 'ItemAction', { action : 'ShowItem', item : this }

    if @data.accessLevel is 'private'
      @credentialLinks.addSubView new CustomLinkView
        title : 'Share'
        item : this
        cssClass : 'HomeAppView--link primary'
        click    : => delegate.emit 'ItemAction', { action : 'ShareItem', item : this }

    if @data.accessLevel isnt 'private' and whoami()._id is @data.originId
      @credentialLinks.addSubView new CustomLinkView
        title    : 'UnShare'
        item     : this
        cssClass : 'HomeAppView--link primary'
        click    : => delegate.emit 'ItemAction', { action : 'UnShareItem', item : this }

  pistachio: ->
    '''
    <div class="credential-info">
      {div.title{#(title)}}{{> @providerTag}}
    </div>
    {{> @credentialLinks}}
    '''
