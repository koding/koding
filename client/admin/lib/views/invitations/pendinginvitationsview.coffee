kd                        = require 'kd'
remote                    = require('app/remote').getInstance()
checkFlag                 = require 'app/util/checkFlag'
InvitedItemView           = require './inviteditemview'
KDCustomHTMLView          = kd.CustomHTMLView
KodingListController      = require 'app/kodinglist/kodinglistcontroller'
TeamMembersCommonView     = require '../members/teammemberscommonview'
InvitationsListController = require './invitationslistcontroller'


module.exports = class PendingInvitationsView extends TeamMembersCommonView

  constructor: (options = {}, data) ->

    options.searchInputPlaceholder      = 'Find by email or first name'
    options.listViewItemOptions       or= { statusType: 'pending' }
    options.statusType                or= 'pending'
    options.useCustomThresholdHandler  ?= no
    options.sortOptions               or= [
      { title: 'Send date',  value: 'modifiedAt' } # sort by -1
      { title: 'Email',      value: 'email' }      # sort by  1
      { title: 'First name', value: 'firstName' }  # sort by  1
      { title: 'Last name',  value: 'lastName' }   # sort by  1
    ]

    super options, data


  createListController: ->

    { statusType, listViewItemOptions, noItemFoundText } = @getOptions()

    groupSlug = @getData().slug

    @listController = new InvitationsListController
      statusType          : statusType
      noItemFoundText     : noItemFoundText
      listViewItemOptions : listViewItemOptions
      fetcherMethod       : (selector, fetchOptions, callback) =>

        method = if selector.query then 'search' else 'some'

        if checkFlag('super-admin') and groupSlug isnt 'koding'
          selector.groupSlug = groupSlug

        selector.status   = statusType
        fetchOptions.sort = @getSortOptions()

        remote.api.JInvitation[method] selector, fetchOptions, callback

    @buildListController()


  fetchMembers: ->

    return  if @isFetching

    @isFetching = yes

    options     = { skip: @listController.filterStates.skip }
    method      = 'some'
    selector    = {}

    if query = @searchInput.getValue()
      method = 'search'
      selector.query = query

    @listController.fetch selector, (invitations) =>
      @listController.addListItems invitations
      @isFetching = no
    , options


  search: ->

    @listController.filterStates.skip = 0
    @refresh()

    if @searchInput.getValue() then @searchClear.show() else @searchClear.hide()


  getSortOptions: ->

    sortDirections = { modifiedAt: -1, email: 1, firstName: 1, lastName: 1 }
    sortType       = @sortSelectBox.getValue()
    sort           = {}
    sort[sortType] = sortDirections[sortType]

    return sort
