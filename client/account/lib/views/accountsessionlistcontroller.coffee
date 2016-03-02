kd                        = require 'kd'
AccountListViewController = require '../controllers/accountlistviewcontroller'
KDHeaderView              = kd.HeaderView
whoami                    = require 'app/util/whoami'


module.exports = class AccountSessionListController extends AccountListViewController

  constructor:(options,data) ->

    options = kd.utils.extend {}, options,
      limit               : 8
      noItemFoundText     : 'You have no active session.'
    super options,data

    @busy = no
    @skip = 0


  followLazyLoad: ->

    @on 'LazyLoadThresholdReached', kd.utils.debounce 300, =>

      return  @hideLazyLoader()  if @busy

      @busy = yes
      limit = @getOption 'limit'
      @skip += limit

      @fetch { @skip, limit }, (err, sessions) =>
        @hideLazyLoader()

        if err or not sessions
          return @busy = no

        @instantiateListItems sessions
        @busy = no


  loadItems: ->
    @removeAllItems()
    @showLazyLoader()

    @fetch {}, (err, sessions) =>

      @hideLazyLoader()
      @instantiateListItems sessions


  fetch: (options = {}, callback) ->

    options.limit or= @getOption 'limit'
    options.sort  or= { 'sessionBegan' : -1 }

    whoami().fetchMySessions options, (err, sessions) =>

      if err
        @hideLazyLoader()
        showError err, \
          KodingError : "Failed to fetch data, try again later."
        return

      callback err, sessions


  loadView: ->

    super

    @hideNoItemWidget()


    @getListView().on 'ItemDeleted', (item) =>
      @removeItem item
      @noItemView.show()  if @getListView().items.length is 0

    @loadItems()
    @followLazyLoad()

