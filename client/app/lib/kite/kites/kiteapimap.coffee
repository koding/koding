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
    reinit          : 'reinit'
    resize          : 'resize'
    restart         : 'restart'
    destroy         : 'destroy'

    # Admin helpers
    addAdmin        : 'admin.add'
    removeAdmin     : 'admin.remove'

    # Domain managament
    setDomain       : 'domain.set'
    addDomain       : 'domain.add'
    unsetDomain     : 'domain.unset'
    removeDomain    : 'domain.remove'

    # Snapshots
    createSnapshot  : 'createSnapshot'

    # Stack, Teams, Credentials related methods
    migrate         : 'migrate'
    bootstrap       : 'bootstrap'
    buildStack      : 'apply'
    checkTemplate   : 'plan'
    checkCredential : 'authenticate'
