kd                 = require 'kd'
hljs               = require 'highlight.js'
KDListView         = kd.ListView
KDModalView        = kd.ModalView
KDOverlayView      = kd.OverlayView
KDNotificationView = kd.NotificationView

showError                 = require 'app/util/showError'
AccountCredentialListItem = require './accountcredentiallistitem'


module.exports = class AccountCredentialList extends KDListView

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'credential-list', options.cssClass
    options.itemClass ?= AccountCredentialListItem

    super options, data


  deleteItem: (item) ->

    credential = item.getData()

    # Since KDModalView.confirm not passing overlay options
    # to the base class (KDModalView) I had to do this hack
    # Remove this when issue fixed in Framework ~ GG
    overlay = new KDOverlayView cssClass: 'second-overlay'

    modal   = KDModalView.confirm
      title       : 'Remove credential'
      description : 'Do you want to remove ?'
      ok          :
        title     : 'Yes'
        callback  :  => credential.delete (err) =>
          modal.destroy()
          @emit 'ItemDeleted', item  unless showError err

    modal.once   'KDObjectWillBeDestroyed', overlay.bound 'destroy'
    overlay.once 'click',                   modal.bound   'destroy'

    return modal


  shareItem: (item) ->

    credential = item.getData()

    @emit "ShowShareCredentialFormFor", credential
    item.setClass 'sharing-item'

    @on 'sharingFormDestroyed', -> item.unsetClass 'sharing-item'


  showItemParticipants: (item) ->

    credential = item.getData()
    credential.fetchUsers (err, users) ->
      kd.info err, users


  showItemContent: (item) ->

    credential = item.getData()
    credential.fetchData (err, data) ->
      unless showError err

        data.meta.publicKey = credential.publicKey

        cred = JSON.stringify data.meta, null, 2
        cred = hljs.highlight('json', cred).value

        new KDModalView
          title          : credential.title
          subtitle       : credential.provider
          cssClass       : 'has-markdown'
          overlay        : yes
          overlayOptions : cssClass : 'second-overlay'
          content        : "<pre><code>#{cred}</code></pre>"

  checkIsBootstrapped: (item) ->

    credential = item.getData()
    credential.isBootstrapped (err, data) ->

      return if kd.warn err  if err
      kd.info 'Bootstrapped?', data


  bootstrap: (item) ->

    credential = item.getData()
    publicKeys = [credential.publicKey]

    console.log { publicKeys }

    { computeController } = kd.singletons

    computeController.getKloud()

      .bootstrap { publicKeys }

      .then (response) ->

        console.log "Bootstrap result:", response

      .catch (err) ->

        console.warn "Bootstrap failed:", err


  verify: (item) ->

    credential = item.getData()
    publicKeys = [credential.publicKey]

    console.log { publicKeys }

    { computeController } = kd.singletons

    computeController.getKloud()

      .checkCredential { publicKeys }

      .then (response) ->

        console.log "Verify result:", response
        response

      .catch (err) ->

        console.warn "Verify failed:", err
        err
