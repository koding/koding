module.exports = KiteAPIMap =

  # Kloud Kite API Mapping
  kloud:

    # Kite Internals
    ping            : 'kite.ping'

    # Eventer
    event           : 'event'

    # Machine related actions, these requires valid machineId
    info            : 'info'
    stop            : 'stop'
    start           : 'start'
    build           : 'build'
    restart         : 'restart'
    destroy         : 'destroy'

    # Admin helpers
    addAdmin        : 'admin.add'
    removeAdmin     : 'admin.remove'

    # Stack, Teams, Credentials related methods
    migrate         : 'migrate'
    bootstrap       : 'bootstrap'
    buildStack      : 'apply'
    checkTemplate   : 'plan'
    checkCredential : 'authenticate'
