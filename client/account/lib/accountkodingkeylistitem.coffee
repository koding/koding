kd                = require 'kd'
KDCustomHTMLView  = kd.CustomHTMLView
KDListItemView    = kd.ListItemView
KDModalView       = kd.ModalView
ContentModal      = require 'app/components/contentModal'
whoami            = require 'app/util/whoami'


module.exports = class AccountKodingKeyListItem extends KDListItemView

  constructor: (options, data) ->
    defaults  =
      tagName : 'li'
    options   = defaults extends options
    super options, data

    @addSubView new KDCustomHTMLView
      tagName      : 'a'
      partial      : 'Revoke Access'
      cssClass     : 'action-link'
      width        : 600
      click        : =>
        { nickname } = whoami().profile
        modal = new ContentModal
          title        : 'Revoke Koding Key Access'
          overlay      : yes
          cssClass     : 'content-modal'
          content      : """
          <div class='modalformline'>
            <p>
              If you revoke access, your computer <strong>#{data.hostname}</strong>
              will not be able to use your Koding account '#{nickname}'. It won't be
              able to receive public url's, deploy your kites etc.
            </p>
            <p>
              If you want to register a new key, you can use <code>$ kd register</code>
              command anytime.
            </p>
            <p>
              Do you really want to revoke <strong>#{data.hostname}</strong>'s access?
            </p>
          </div>
          """
          buttons      :
            'Close'    :
              style    : 'solid medium'
              callback : (event) ->
                modal.destroy()
            'Yes, Revoke Access':
              style    : 'solid medium'
              callback : (event) =>
                @revokeAccess options, data
                @destroy()
                modal.destroy()

    @addSubView new KDCustomHTMLView
      tagName     : 'a'
      partial     : 'View access key'
      click       : ->
        modal = new ContentModal
          title        : 'Access Key'
          width        : 500
          overlay      : yes
          cssClass     : 'content-modal'
          content      : """
          <div class='modalformline'>
            <p>
              This key is for <strong>#{data.hostname}</strong>
            </p>
            <p>
              Please do not share this key anyone!
            </p>
            <p>
              <code>#{data.key}</code>
            </p>
          </div>
          """

  revokeAccess: (options, data) ->
    data.revoke()

  partial: (data) ->
    """
      <span class="labelish">#{data.hostname or "Unknown Host"}</span>
    """
