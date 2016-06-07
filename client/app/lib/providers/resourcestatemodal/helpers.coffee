progressStatusMap  =
  'start started'  : 'Starting VM'
  'stop started'   : 'Stopping VM'
  'stop finished'  : 'VM is stopped'
  'start finished' : 'VM is ready'


module.exports =

  formatProgressStatus: (message = '') ->

    return  unless message

    message = progressStatusMap[message] or message
    message = message.replace 'machine', 'VM'
    message = message.capitalize()
    message = "#{message}..."  unless message.lastIndexOf('...') is message.length - 3

    return message


  isTargetEvent: (event, target) ->

    { eventId } = event
    return eventId?.indexOf(target._id) > -1
