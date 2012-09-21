{dash} = require 'sinkrow'

asyncThing = -> setTimeout (-> queue.fin()), Math.random()*1000

queue = [asyncThing, asyncThing, asyncThing]

dash queue, -> console.log 'all fin'