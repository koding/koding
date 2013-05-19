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

  partial:(data)->
    """
      <span class="labelish">#{data.hostname or "Unknown Host"}</span>
      <span class="ttag">#{data.key}</span>
    """
