kd          = require 'kd'
React       = require 'kd-react'
expect      = require 'expect'
toImmutable = require 'app/util/toImmutable'
TestUtils   = require 'react-addons-test-utils'
mock        = require '../../../../mocks/mockingjay'

{ renderIntoDocument } = TestUtils

module.exports = expectCorrectRoute = (ModalComponent, id, typeConstant, route) ->

  modal = renderIntoDocument(<ModalComponent.Container isOpen={no}/>)

  expect.spyOn kd.singletons.router, 'handleRoute'

  channelOptions = if typeConstant is 'privatemessage'
  then { channelId: id, typeConstant }
  else { channelName: id, typeConstant }

  mockChannel = mock.getMockChannel channelOptions

  threadOptions = if typeConstant is 'privatemessage'
  then { channelId: id, channel: mockChannel }
  else { channel: mockChannel }

  mockThread  = mock.getMockThread threadOptions

  modal.setState selectedThread: toImmutable mockThread
  modal.onClose()

  result = expect(kd.singletons.router.handleRoute)
  result.toHaveBeenCalled()
  result.toHaveBeenCalledWith(route)
  result.toNotThrow()
