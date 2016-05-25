progressStatusMap  =
  'start started'  : 'Starting VM'
  'stop started'   : 'Stopping VM'
  'stop finished'  : 'VM is stopped'
  'start finished' : 'VM is ready'


module.exports =

  formatProgressStatus: (message = '') ->

    message = progressStatusMap[message] or message
    message = message.replace 'machine', 'VM'
    message = message.capitalize()

    return message
