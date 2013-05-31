class AccountKodingKeyListController extends KDListViewController

  constructor:(options, data)->
    options.cssClass = "koding-keys"
    super options,data

  loadView: ->
    super
    KD.remote.api.JKodingKey.fetchAll {}, (err, keys) =>
      if err then warn err
      else
        @instantiateListItems keys

class AccountKodingKeyList extends KDListView

  constructor:(options, data)->
    defaults    =
      tagName   : "ul"
      itemClass : AccountKodingKeyListItem
    options = defaults extends options
    super options, data


class AccountKodingKeyListItem extends KDListItemView

  constructor:(options, data)->
    defaults  =
      tagName : "li"
    options   = defaults extends options
    super options, data

    @addSubView deleteKey = new KDCustomHTMLView
      tagName      : "a"
      partial      : "Revoke Access"
      cssClass     : "action-link"
      click        : =>
        {nickname} = KD.whoami().profile
        modal = new KDModalView
          title        : "Revoke Koding Key Access"
          overlay      : yes
          cssClass     : "new-kdmodal"
          content      : """
          <div class='modalformline'>
            <p>
              If you revoke access, your computer '<strong>#{data.hostname}</strong>' 
              will not be able to use your Koding account '#{nickname}'. It won't be 
              able to receive public url's, deploy your kites etc.
            </p>
            <p>
              If you want to register a new key, you can use <code>"kd register"</code>
              command anytime.
            </p>
            <p>
              Do you really want to revoke <strong>#{data.hostname}</strong>'s access?
            </p>
          </div>
          """
          buttons      :
            "Yes, Revoke Access":
              style    : "modal-clean-red"
              callback : (event)=>
                @revokeAccess options, data
                @destroy()
                modal.destroy()
            "Close"    :
              style    : "modal-clean-gray"
              callback : (event)->
                modal.destroy()

    @addSubView viewKey = new KDCustomHTMLView
      tagName     : "a"
      partial     : "View access key"
      click       : ->
        modal = new KDModalView
          title        : "#{data.hostname} Access Key"
          width        : 500
          overlay      : yes
          cssClass     : "new-kdmodal"
          content      : """
          <div class='modalformline'>
            <p>
              Please do not share this key anyone!
            </p>
            <p>
              <code>#{data.key}</code>
            </p>
          </div>
          """

  revokeAccess: (options, data)->
    data.revoke()

  partial:(data)->
    """
      <span class="labelish">#{data.hostname or "Unknown Host"}</span>
    """
