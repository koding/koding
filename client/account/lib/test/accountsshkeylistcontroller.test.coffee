kd                          = require 'kd'
mock                        = require '../../../mocks/mockingjay'
expect                      = require 'expect'
KDListItemView              = kd.ListItemView
AccountNewSshKeyView        = require 'account/views/accountnewsshkeyview'
KodingListController        = require 'app/kodinglist/kodinglistcontroller'
AccountSshKeyListController = require 'account/views/accountsshkeylistcontroller'


describe 'AccountSshKeyListController', ->

  describe 'constructor', ->

    it 'should be extended from KodingListController', ->

      listController = new AccountSshKeyListController

      expect(listController instanceof KodingListController).toBeTruthy()

    it 'should instantiate with default options', ->

      listController = new AccountSshKeyListController

      { noItemFoundText, fetcherMethod } = listController.getOptions()

      expect(noItemFoundText).toEqual 'You have no SSH key.'
      expect(fetcherMethod).toExist()


  describe '::bindEvents', ->

    it 'should call saveItems method when UpdatedItems event is emitted', ->

      listController = new AccountSshKeyListController
      spy = expect.spyOn listController, 'saveItems'
      listController.getListView().emit 'ItemAction', { action : 'UpdatedItems' }

      expect(spy).toHaveBeenCalled()

    it 'should call deleteItem method when RemoveItem event is emitted', ->

      listController  = new AccountSshKeyListController
      item            = new KDListItemView
      spy             = expect.spyOn listController, 'deleteItem'

      listController.getListView().emit 'ItemAction', { action : 'RemoveItem', item }

      expect(spy).toHaveBeenCalledWith item

    it 'should call submitNewItem method when NewItemSubmitted event is emitted', ->

      listController  = new AccountSshKeyListController
      item            = new KDListItemView
      spy             = expect.spyOn listController, 'submitNewItem'

      listController.getListView().emit 'ItemAction', { action : 'NewItemSubmitted', item }

      expect(spy).toHaveBeenCalledWith item

    it 'should call editItem method when EditItem event is emitted', ->

      listController  = new AccountSshKeyListController
      item            = new KDListItemView
      spy             = expect.spyOn listController, 'editItem'

      listController.getListView().emit 'ItemAction', { action : 'EditItem', item }

      expect(spy).toHaveBeenCalledWith item

    it 'should call cancelItem method when CancelItem event is emitted', ->

      listController  = new AccountSshKeyListController
      item            = new KDListItemView
      spy             = expect.spyOn listController, 'cancelItem'

      listController.getListView().emit 'ItemAction', { action : 'CancelItem', item }

      expect(spy).toHaveBeenCalledWith item


  describe '::deleteItem', ->

    it 'should call cancelItem and removeItem methods', ->

      listController = new AccountSshKeyListController
      item           = new AccountNewSshKeyView

      cancelItemSpy  = expect.spyOn listController, 'cancelItem'
      removeItemSpy  = expect.spyOn listController, 'removeItem'

      listController.getListView().emit 'ItemAction', { action : 'RemoveItem', item }

      expect(cancelItemSpy).toHaveBeenCalled()
      expect(removeItemSpy).toHaveBeenCalled()


    it 'should not call saveItems and showDeleteModal if the item is new', ->

      listController = new AccountSshKeyListController
      item           = new AccountNewSshKeyView

      saveItemsSpy        = expect.spyOn listController, 'saveItems'
      showDeleteModalSpy  = expect.spyOn listController, 'showDeleteModal'

      listController.getListView().emit 'ItemAction', { action : 'RemoveItem', item }

      expect(saveItemsSpy).toNotHaveBeenCalled()
      expect(showDeleteModalSpy).toNotHaveBeenCalled


  describe '::isMachineActive', ->

    it 'should return status of given machine', ->

      listController  = new AccountSshKeyListController
      isMachineActive = listController.isMachineActive mock.getMockMachine()
      expect(isMachineActive).toBeFalsy()
