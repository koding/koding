kd                        = require 'kd'
AccountListViewController = require '../controllers/accountlistviewcontroller'
AccountNewSshKeyView      = require './accountnewsshkeyview'
remote                    = require('app/remote').getInstance()
KDHeaderView              = kd.HeaderView
Machine                   = require 'app/providers/machine'
SshKey                    = require 'app/util/sshkey'
KDModalView               = kd.ModalView
nick                      = require 'app/util/nick'
environmentDataProvider   = require 'app/userenvironmentdataprovider'
whoami                    = require 'app/util/whoami'


module.exports = class AccountSessionListController extends AccountListViewController

  constructor:(options,data) ->

    options.noItemFoundText = "You have no active session."
    super options,data

    @fetchSessions()


  fetchSessions: ->

    @removeAllItems()
    @showLazyLoader no

    whoami().fetchMySessions (err, sessions) =>
      @instantiateListItems sessions
      @hideLazyLoader()

      @header?.destroy()

      @header = new KDHeaderView
        title : 'Active Sessions'

      @getListView().addSubView @header, '', yes


  loadView: ->

    super

    @hideNoItemWidget()

    @listView.on 'ItemDeleted', (item) =>
      @removeItem item
      @noItemView.show()  if @listView.items.length is 0
