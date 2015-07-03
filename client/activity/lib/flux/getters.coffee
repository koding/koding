immutable = require 'immutable'

threadsMap = ['threads']
messagesMap = ['messages']

threads = [
  threadsMap
  messagesMap
  (threadsMap, messagesMap) ->
    threadsMap.map (thread) ->
      # convert messageId list with message list.
      messages = thread.get('messages').map (messageId) -> messagesMap.get messageId
      thread.set 'messages', messages
]

selectedChannelThreadId = ['selectedChannelThreadId']

messages = [
  threadsMap
  (threadsMap) -> threadsMap.toList()
]

selectedChannelThread = [
  selectedChannelThreadId
  threads
  (selectedChannelThreadId, threads) -> threads.get selectedChannelThreadId
]

selectedChannelThreadMessages = [
  selectedChannelThread
  (selectedChannelThread) ->
    if selectedChannelThread?.has 'messages'
      selectedChannelThread.get 'messages'
    else
      immutable.List()
]

module.exports = {
  threadsMap
  selectedChannelThreadId
  selectedChannelThread
  selectedChannelThreadMessages
  messages
}

