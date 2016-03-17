kd      = require 'kd'
expect  = require 'expect'

KDModalView = kd.ModalView

KodingListView       = require 'app/kodinglist/kodinglistview'
KodingListController = require 'app/kodinglist/kodinglistcontroller'


describe 'KodingListView', ->

  describe 'constructor', ->

    it 'should has "koding-listview" css class', ->

      listController = new KodingListController { fetcherMethod : kd.noop }
      hasClass       = listController.getListView().hasClass 'koding-listview'

      expect(hasClass).toBeTruthy()


  describe '::askForConfirm', ->

    it 'should show confirm modal with given options', ->

      listController  = new KodingListController { fetcherMethod : kd.noop }
      modalOptions    =
        callback      : kd.noop
        title         : 'Remove item'
        description   : 'Are you sure?'

      spy = expect.spyOn KDModalView, 'confirm'

      modal = listController.getListView().askForConfirm modalOptions

      parameters = spy.calls.first.arguments.first

      expect(parameters.title).toEqual modalOptions.title
      expect(parameters.description).toEqual modalOptions.description
