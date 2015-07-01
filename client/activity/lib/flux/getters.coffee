threadsMap = ['channelsMessages']
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

selectedThreadId = ['selectedChannelId']

messages = [
  threadsMap
  (threadsMap) -> threadsMap.toList()
]

selectedThread = [
  selectedThreadId
  threads
  (selectedThreadId, threads) -> threads.get selectedThreadId
]

module.exports = {
  threadsMap
  selectedThreadId
  selectedThread
  messages
}

