_ = require 'lodash'
kd = require 'kd'
hljs = require 'highlight.js'
showError = require 'app/util/showError'
contentModal = require 'app/components/contentModal'
applyMarkdown = require 'app/util/applyMarkdown'
KodingListView = require 'app/kodinglist/kodinglistview'
AccountCredentialListItem = require './accountcredentiallistitem'
AccountCredentialEditModal = require './accountcredentialeditmodal'


module.exports = class AccountCredentialList extends KodingListView

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'credential-list', options.cssClass
    options.itemClass ?= AccountCredentialListItem

    super options, data

    @on 'ItemDeleted', @bound 'removeItem'


  showCredential: (options = {}) ->

    { credential, cred } = options

    new contentModal
      width : 600
      overlay : yes
      title : "<h1>#{credential.title}</h1>"
      cssClass : 'has-markdown credential-modal'
      overlayOptions : { cssClass : 'second-overlay' }
      content : "<h2>#{credential.provider}</h2><p><pre><code>#{cred}</code></pre></p>"



  askForConfirm: (options, callback) ->

    { credential, bootstrapped } = options

    description = applyMarkdown if bootstrapped then "
        This **#{credential.title}** credential is bootstrapped before. It
        means that you have modified data on your **#{credential.provider}**
        account.
        \n\n
        You can remove this credential here and manually cleanup the resources
        which are created on your provider. Or you can **destroy** all
        bootstrapped data and resources along with this credential.
        \n\n
        **WARNING!** by destroying resources you'd destroy **ALL RESOURCES**;
        your team members' instances, volumes, keypairs, and **everything else
        we've created on their accounts**.
        \n\n
        **WARNING!** removing a credential can cause your stacks or instances
        to stop working properly, please make sure that you don't have any
        stack or stack templates that depend on this credential.
      " else "
        **WARNING!** removing a credential can cause your stacks or instances
        to stop working properly, please make sure that you don't have any
        stack or stack templates that depend on this credential.
        \n\n
        Do you want to remove **#{credential.title}**?
      "

    unless credential.owner
      description = applyMarkdown "
        You don't have permission to delete **#{credential.title}**
        credential, however you can still remove this credential
        from your account.
        \n\n
        **WARNING!** Removing this credential from your account can cause
        your stacks or instances stop working properly if they
        depend on this credential.
        \n\n
        Do you want to remove it from your account?
      "
      bootstrapped = no
      removeButtonTitle = 'Remove Access'


    modal = new contentModal
      width : 600
      overlay : yes
      title          : 'Remove credential'
      content        : "<div class='modalformline'>#{description}</div>"
      cssClass       : 'remove-credential'
      attributes     :
        testpath     : if bootstrapped then 'destroyCredentialModal' else 'removeCredentialModal'
      overlayOptions :
        cssClass     : 'second-overlay'
        overlayClick : yes
      buttons        :
        cancel       :
          title      : 'Cancel'
          style      : 'solid light-gray medium'
          callback   : ->
            modal.destroy()
            callback { action : 'Cancel', modal }
        DestroyAll   :
          title      : 'Destroy Everything'
          style      : "solid red medium #{unless bootstrapped then 'hidden'}"
          attributes :
            testpath : 'destroyAll'
          loader     : yes
          callback   : ->
            callback { action : 'DestroyAll', modal }
        Remove       :
          title      : removeButtonTitle ? 'Remove Credential'
          style      : 'solid red medium'
          attributes :
            testpath : 'removeCredential'
          loader     : yes
          callback   : ->
            callback { action : 'Remove', modal }


  showCredentialEditModal: (options = {}) ->

    { provider, credential, data } = options

    new AccountCredentialEditModal { provider, credential }, data


  # Move this method to controller.
  verify: (item) ->

    credential  = item.getData()
    identifiers = [credential.identifier]

    { computeController } = kd.singletons

    computeController.getKloud()

      .checkCredential { identifiers, provider: credential.provider }

      .then (response) ->

        console.log 'Verify result:', response
        response

      .catch (err) ->

        console.warn 'Verify failed:', err
        err
