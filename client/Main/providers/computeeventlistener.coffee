class ComputeEventListener extends KDObject

  constructor:->

    @kloud          = KD.singletons.kontrol.getKite
      name          : "kloud"
      environment   : "vagrant"

    @listeners      = []
    @tickInProgress = no
    @running        = no
    @timeout        = 5000
    @timer          = null


  listen:->

    return  if @running
    @running = yes
    @timer = KD.utils.repeat @timeout, @bound 'tick'


  stop:->

    return  unless @running
    @running = no
    KD.utils.killWait @timer


  addListener:(type, eventId)->

    @listeners.push { type, eventId }


  tick:->

    return  unless @listeners.length
    return  if @tickInProgress
    @tickInProgress = yes

    @kloud.event(@listeners)

    .then (res)=>

      log res

    .catch (err)=>

      warn "Eventer error:", err
      @stop()

    .finally =>

      @tickInProgress = no

