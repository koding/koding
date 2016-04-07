kd                        = require 'kd'
checkFlag                 = require 'app/util/checkFlag'
InvitedItemView           = require './inviteditemview'
KDCustomHTMLView          = kd.CustomHTMLView
KodingListController      = require 'app/kodinglist/kodinglistcontroller'
TeamMembersCommonView     = require '../members/teammemberscommonview'
InvitationsListController = require './invitationslistcontroller'


module.exports = class PendingInvitationsView extends TeamMembersCommonView

  constructor: (options = {}, data) ->

    options.searchInputPlaceholder   = 'Find by email or first name'
    options.listViewItemOptions    or= { statusType: 'pending' }
    options.statusType             or= 'pending'
    options.sortOptions            or= [
      { title: 'Send date',  value: 'modifiedAt' } # sort by -1
      { title: 'Email',      value: 'email' }      # sort by  1
      { title: 'First name', value: 'firstName' }  # sort by  1
      { title: 'Last name',  value: 'lastName' }   # sort by  1
    ]

    super options, data


  createListController: ->

    { statusType, listViewItemOptions, noItemFoundText } = @getOptions()

    @listController = new InvitationsListController { statusType, listViewItemOptions, noItemFoundText }

    @buildListController()


  fetchMembers: ->

    return  if @isFetching

    @isFetching    = yes
    query          = @searchInput.getValue()
    options        = { @skip, sort: @getSortOptions() }
    method         = 'some'
    selector       = { }
    isSuperAdmin   = checkFlag 'super-admin'

    if query
      method = 'search'
      selector.query = query

    groupSlug = @getData().slug
    if isSuperAdmin and groupSlug isnt 'koding'
      selector.groupSlug = groupSlug

    @listController.fetch selector, (invitations) =>
      @listMembers invitations
      @isFetching = no
    , options


  search: ->

    @skip  = 0
    @query = @searchInput.getValue()

    @refresh()

    if @query.length then @searchClear.show() else @searchClear.hide()


  getSortOptions: ->

    sortDirections = { modifiedAt: -1, email: 1, firstName: 1, lastName: 1 }
    sortType       = @sortSelectBox.getValue()
    sort           = {}
    sort[sortType] = sortDirections[sortType]

    return sort
