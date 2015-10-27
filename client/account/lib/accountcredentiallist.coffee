kd                          = require 'kd'
hljs                        = require 'highlight.js'

KDListView                  = kd.ListView
KDModalView                 = kd.ModalView
KDOverlayView               = kd.OverlayView
KDNotificationView          = kd.NotificationView

showError                   = require 'app/util/showError'
applyMarkdown               = require 'app/util/applyMarkdown'

AccountCredentialListItem   = require './accountcredentiallistitem'
AccountCredentialEditModal  = require './accountcredentialeditmodal'


module.exports = class AccountCredentialList extends KDListView

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'credential-list', options.cssClass
    options.itemClass ?= AccountCredentialListItem

    super options, data


  deleteItem: (item) ->

    credential = item.getData()

    if credential.inuse
      new kd.NotificationView
        title: 'This credential is currently in-use'
      return

    credential.isBootstrapped (err, bootstrapped) =>

      kd.warn "Bootstrap check failed:", { credential, err }  if err

      description = applyMarkdown if bootstrapped then "
        This **#{credential.title}** credential is bootstrapped before which
        means that you have modified data on your **#{credential.provider}**
        account.
        \n\n
        You can remove this credential from Koding and manually cleanup
        the resources created on your provider or you can **destroy** all
        bootstrapped data and resources along with credential.
        \n\n
        **WARNING!** destroying resources includes **ALL RESOURCES**; your
        team member's instances, volumes, keypairs and **everything else we've
        created on your account**.
        \n\n
        **WARNING!** removing a credential can cause your stacks or instances
        to stop working properly, please make sure that you don't have any
        stacktemplates relying on this credential.
      " else "
        **WARNING!** removing a credential can cause your stacks or instances
        to stop working properly, please make sure that you don't have any
        stacktemplates relying on this credential.
        \n\n
        Do you want to remove **#{credential.title}** ?
      "

      removeCredential = =>
        credential.delete (err) =>
          @emit 'ItemDeleted', item  unless showError err
          modal.destroy()

      modal            = new KDModalView
        title          : 'Remove credential'
        content        : "<div class='modalformline'>#{description}</div>"
        cssClass       : 'has-markdown'
        overlay        : yes
        overlayOptions :
          cssClass     : 'second-overlay'
          overlayClick : yes
        buttons        :
          Remove       :
            title      : 'Remove Credential'
            style      : 'solid red medium'
            loader     : yes
            callback   : =>
              modal.buttons.DestroyAll.disable()
              removeCredential()
          DestroyAll   :
            title      : 'Destroy Everything'
            style      : "solid red medium #{if !bootstrapped then 'hidden'}"
            loader     : yes
            callback   : =>
              modal.buttons.Remove.disable()
              @destroyResources credential, (err) ->
                if err
                  modal.buttons.DestroyAll.hideLoader()
                  modal.buttons.Remove.enable()
                else
                  removeCredential()
          cancel       :
            title      : 'Cancel'
            style      : 'solid light-gray medium'
            callback   : -> modal.destroy()


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
      return if showError err

      data.meta.identifier = credential.identifier

      cred = JSON.stringify data.meta, null, 2
      cred = hljs.highlight('json', cred).value

      new KDModalView
        title          : credential.title
        subtitle       : credential.provider
        cssClass       : 'has-markdown'
        overlay        : yes
        overlayOptions : cssClass : 'second-overlay'
        content        : "<pre><code>#{cred}</code></pre>"


  editItem: (item) ->

    credential    = item.getData()
    { provider }  = credential

    # Don't show the edit button for aws credentials in list. Gokmen'll on it.
    if provider is 'aws'
      return showError "This AWS credential can't be edited for now."

    credential.fetchData (err, data) ->
      return if showError err

      data.title = credential.title

      new AccountCredentialEditModal { provider, credential }, data


  destroyResources: (credential, callback) ->

    identifiers = [ credential.identifier ]

    kd.singletons.computeController.getKloud()
      .bootstrap { identifiers, destroy: yes }
      .then -> callback null
      .catch (err) ->
        kd.singletons.computeController.ui.showComputeError
          title   : 'An error occured while destroying resources'
          message : "
            Some errors occurred while destroying resources that are created
            with this credential.
            <br/>
            You can either visit
            <a href='http://console.aws.amazon.com/' target=_blank>
            console.aws.amazon.com
            </a> to clear the EC2 instances and try this again, or go ahead
            and delete this credential here but you will need to destroy your
            resources manually from AWS console later.
          "
          errorMessage : err?.message ? err
        callback err


  verify: (item) ->

    credential = item.getData()
    identifiers = [credential.identifier]

    console.log { identifiers }

    { computeController } = kd.singletons

    computeController.getKloud()

      .checkCredential { identifiers }

      .then (response) ->

        console.log "Verify result:", response
        response

      .catch (err) ->

        console.warn "Verify failed:", err
        err
