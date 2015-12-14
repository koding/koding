kd        = require 'kd'
remote    = require('app/remote').getInstance()
showError = require 'app/util/showError'

AccountListViewController = require 'account/controllers/accountlistviewcontroller'


module.exports = class TeamListController extends AccountListViewController


  constructor: (options = {}, data) ->

    options.noItemFoundText  ?= 'No teams found!'
    super options, data

    @loadItems()


  loadItems: (slug) ->

    @removeAllItems()
    @getListView()._currentItem = null
    @showLazyLoader()

    { JGroup } = remote.api
    query      = {
      slug: { $nin: ['koding', 'guests'] }
    }

    if slug
      query.slug.$in = [ slug ]

    # TODO Add Pagination here ~ GG
    JGroup.someWithRelationship query, { limit: 30 }, (err, teams) =>

      @hideLazyLoader()

      return if showError err, \
        KodingError : "Failed to fetch teams, try again later."

      @instantiateListItems teams

      @emit 'ItemsLoaded', teams
