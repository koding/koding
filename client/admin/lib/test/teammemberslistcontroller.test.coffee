kd                        = require 'kd'
mock                      = require '../../../mocks/mockingjay'
remote                    = require('app/remote').getInstance()
expect                    = require 'expect'
whoami                    = require 'app/util/whoami'
KodingListController      = require 'app/kodinglist/kodinglistcontroller'
TeamMembersListController = require '../views/members/teammemberslistcontroller'

member  = remote.revive mock.getMockAccount()
members = [ member ]


describe 'TeamMembersListController', ->

  describe 'constructor', ->

    it 'should be extended from KodingListController ', ->

      fetcherMethod   = kd.noop
      listController  = new TeamMembersListController { fetcherMethod }

      expect(listController).toBeA KodingListController

    it 'should instantiate with default options', ->

      fetcherMethod               = kd.noop
      listController              = new TeamMembersListController { fetcherMethod }
      { lazyLoadThreshold, sort } = listController.getOptions()

      expect(lazyLoadThreshold).toBe .99
      expect(sort.timestamp).toBe -1


  describe '::addListItems', ->

    it 'should show no item widget if there is no member', ->

      fetcherMethod       = kd.noop
      listController      = new TeamMembersListController { fetcherMethod }

      getItemCountSpy     = expect.spyOn(listController, 'getItemCount').andReturn 0
      showNoItemWidgetSpy = expect.spyOn listController, 'showNoItemWidget'

      listController.addListItems [], 'admin'

      expect(showNoItemWidgetSpy).toHaveBeenCalled()

    it 'should add all members to list if member type is "blocked"', ->

      fetcherMethod   = kd.noop
      listController  = new TeamMembersListController { fetcherMethod, memberType : 'Blocked', limit : 1 }

      addItemSpy      = expect.spyOn listController, 'addItem'
      emitSpy         = expect.spyOn listController, 'emit'

      listController.addListItems members, 'admin'

      expect(addItemSpy).toHaveBeenCalledWith member
      expect(emitSpy.calls.first.arguments.first).toBe 'CalculateAndFetchMoreIfNeeded'

    it 'should fetch user\'s role and filter admins', ->

      fetcherMethod     = kd.noop
      listController    = new TeamMembersListController { fetcherMethod, memberType : 'Admins', defaultMemberRole : 'member', limit : 1 }

      fetchUserRolesSpy = expect.spyOn(listController, 'fetchUserRoles').andCall (members, callback) ->
        member.roles    = [ 'admin', 'member' ]
        callback [ member ]

      emitSpy           = expect.spyOn listController, 'emit'
      addItemSpy        = expect.spyOn listController, 'addItem'

      listController.addListItems members, 'admin'

      expect(addItemSpy).toHaveBeenCalledWith member
      expect(emitSpy.calls.first.arguments.first).toBe 'CalculateAndFetchMoreIfNeeded'

    it 'should show no item widget if there is no member after filter', ->

      fetcherMethod     = kd.noop
      listController    = new TeamMembersListController { fetcherMethod, memberType : 'Admins', defaultMemberRole : 'member', limit : 1 }

      fetchUserRolesSpy = expect.spyOn(listController, 'fetchUserRoles').andCall (members, callback) ->
        member.roles    = [ 'owner' ]
        callback [ member ]

      showNoItemWidgetSpy = expect.spyOn listController, 'showNoItemWidget'

      listController.addListItems members, 'admin'

      expect(showNoItemWidgetSpy).toHaveBeenCalled()


    it 'should call hideLazyLoader method and emit "ShowSearchContainer" event', ->

      fetcherMethod     = kd.noop
      listController    = new TeamMembersListController { fetcherMethod, memberType : 'Admins', defaultMemberRole : 'member', limit : 1 }

      fetchUserRolesSpy = expect.spyOn(listController, 'fetchUserRoles').andCall (members, callback) ->
        member.roles    = [ 'admin', 'member' ]
        callback [ member ]

      hideLazyLoaderSpy = expect.spyOn listController, 'hideLazyLoader'
      emitSpy           = expect.spyOn listController, 'emit'

      listController.addListItems members, 'admin'

      targetCalls       = emitSpy.calls.filter (c) -> c.arguments.first is 'ShowSearchContainer'

      expect(hideLazyLoaderSpy).toHaveBeenCalled()
      expect(targetCalls.length).toBe 1


  describe '::fetchUserRoles', ->

    it 'should call fetchUserRoles method of JGroup with given ids', ->

      fetcherMethod     = kd.noop
      listController    = new TeamMembersListController { fetcherMethod }, mock.getMockGroup()

      group             = listController.getData()
      spy               = expect.spyOn group, 'fetchUserRoles'

      listController.fetchUserRoles members

      ids = spy.calls.first.arguments[0]

      expect(ids[0]).toBe member._id
      expect(ids[1]).toBe whoami().getId()

    it 'should emit "ErrorHappened" event if there is any error', ->

      fetcherMethod     = kd.noop
      listController    = new TeamMembersListController { fetcherMethod }, mock.getMockGroup()
      group             = listController.getData()
      err               = new Error 'error !'

      emitSpy           = expect.spyOn listController, 'emit'

      expect.spyOn(group, 'fetchUserRoles').andCall (ids, callback) ->
        callback err, []

      listController.fetchUserRoles members

      expect(emitSpy.calls.first.arguments[0]).toBe 'ErrorHappened'
      expect(emitSpy.calls.first.arguments[1]).toBe err

    it 'should add roles to user', (done) ->

      fetcherMethod     = kd.noop
      listController    = new TeamMembersListController { fetcherMethod }, mock.getMockGroup()
      group             = listController.getData()

      expect.spyOn(group, 'fetchUserRoles').andCall (ids, callback) ->
        callback null, []

      listController.fetchUserRoles members, (items) ->

        expect(items.first.roles).toEqual [ 'admin' , 'member']
        expect(listController.loggedInUserRoles).toEqual [ 'owner', 'admin', 'member' ]
        done()
