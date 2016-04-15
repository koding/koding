kd                        = require 'kd'
mock                      = require '../../../mocks/mockingjay'
remote                    = require('app/remote').getInstance()
expect                    = require 'expect'
KDButtonView              = kd.ButtonView
KodingListView            = require 'app/kodinglist/kodinglistview'
InvitedItemView           = require '../views/invitations/inviteditemview'
KodingListController      = require 'app/kodinglist/kodinglistcontroller'
InvitationsListController = require '../views/invitations/invitationslistcontroller'

mockInvitation    = mock.getMockInvitation()
item              = new InvitedItemView {}, mockInvitation
item.revokeButton = new KDButtonView
item.resendButton = new KDButtonView
fetcherMethod     = kd.noop


describe 'InvitationsListController', ->

  afterEach -> expect.restoreSpies()

  describe 'constructor', ->

    it 'should instantiate with default options', ->

      listController = new InvitationsListController { fetcherMethod }
      listView       = listController.getListView()

      { noItemFoundText, statusType, lazyLoadThreshold, viewOptions, fetcherMethod } = listController.getOptions()

      expect(noItemFoundText).toEqual 'There is no pending invitation.'
      expect(statusType).toEqual 'pending'
      expect(lazyLoadThreshold).toBe 0.99
      expect(viewOptions.wrapper).toBeTruthy()
      expect(fetcherMethod).toBeA 'function'
      expect(listView).toBeA KodingListView


  describe 'bindEvents', ->

    it 'should handle Resend event', ->

      listController = new InvitationsListController { fetcherMethod }
      listView       = listController.getListView()
      spy            = expect.spyOn listController, 'resend'

      listView.emit 'ItemAction', { action : 'Resend', item }

      expect(spy).toHaveBeenCalledWith item

    it 'should handle Revoke (RemoveItem) event', ->

      listController = new InvitationsListController { fetcherMethod }
      listView       = listController.getListView()
      spy            = expect.spyOn listController, 'removeItem'

      listView.emit 'ItemAction', { action : 'RemoveItem', item }

      expect(spy).toHaveBeenCalled()


  describe '::removeItem', ->

    it 'should remove item completely if no error', ->

      listController = new InvitationsListController { fetcherMethod }
      listView       = listController.getListView()

      removeSpy      = expect.spyOn(mockInvitation, 'remove').andCall (callback) -> callback null
      emitSpy        = expect.spyOn listView, 'emit'

      listView.emit 'ItemAction', { action : 'RemoveItem', item }

      expect(emitSpy.calls.first.arguments[0]).toEqual 'ItemAction'
      expect(emitSpy.calls.first.arguments[1].action).toEqual 'RemoveItem'
      expect(emitSpy.calls.first.arguments[1].item).toBe item

    it 'should hide lazy loader of button if err', ->

      listController = new InvitationsListController { fetcherMethod }
      listView       = listController.getListView()

      removeSpy      = expect.spyOn(mockInvitation, 'remove').andCall (callback) -> callback new Error 'error!'
      itemSpy        = expect.spyOn item.revokeButton, 'hideLoader'

      listView.emit 'ItemAction', { action : 'RemoveItem', item }

      expect(itemSpy).toHaveBeenCalled()


  describe '::resend', ->

    it 'should call sendInvitationByCode with given code', ->

      listController = new InvitationsListController { fetcherMethod }
      listView       = listController.getListView()

      spy            = expect.spyOn remote.api.JInvitation, 'sendInvitationByCode'

      listView.emit 'ItemAction', { action : 'Resend', item }

      expect(spy.calls.first.arguments[0]).toEqual item.getData().code

    it 'should hide loader of resend button', ->

      listController = new InvitationsListController { fetcherMethod }
      listView       = listController.getListView()

      remoteSpy      = expect.spyOn(remote.api.JInvitation, 'sendInvitationByCode').andCall (code, callback) -> callback null
      buttonSpy      = expect.spyOn item.resendButton, 'hideLoader'

      listView.emit 'ItemAction', { action : 'Resend', item }

      expect(buttonSpy).toHaveBeenCalled()
