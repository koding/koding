class Base extends EventEmitter
  
  @inheritanceChain = (Class, glue)->
    proto = Class.prototype
    chain = [Class]
    while proto = proto.__proto__
      chain.push proto.constructor
    if glue then (constructor.name for constructor in chain).join glue
    else chain
  
  inheritanceChain:(glue)->
    Base.inheritanceChain @constructor, glue
  
  whenReady:(instance, callback)->
    [callback, instance] = [instance, callback] unless callback
    instance or= @
    if instance.readyState
      callback()
    else
      instance.on 'ready', =>
        instance.readyState = yes
        callback()