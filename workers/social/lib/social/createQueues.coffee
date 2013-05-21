{argv}   = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")
amqp = require 'amqp'


KONFIG.mq['vhost'] = '/activities'

console.log(KONFIG.mq)



# simple scenerio
# E: activities
# E:   \_ user_1
# Q:        \_ user_2
# Q:        \_ user_3



users = {}
max_user_count = 10000
followee_count = 200

randomFollowees = (count, exclude_user_id)=>
    ret = {}
    start_user_id = Math.floor((Math.random()* max_user_count-1 )+1) + 1
    for i in [0...count]
        user_id = start_user_id + i
        if user_id isnt exclude_user_id and not ret[user_id]
            if users[user_id]
                ret[user_id] = user_id
    ret

createExchangeForUser= (user)=>
    @connection.exchange "user_#{user.id}", {type: 'fanout', autoDelete:no, durable: yes, exclusive: no}, (userExchange) =>
        userExchange.bind "activities", "user_#{user.id}", ''
        userExchange.on 'exchangeBindOk', =>
            #console.log("created exchange - user_#{user.id}")
            for follower in user.followees
                #console.log("creating queue", "user_#{follower}_queue")
                @connection.queue "user_#{follower}_queue", {exclusive: no}, (userQueue)=>
                    userQueue.bind "user_#{user.id}", "user_#{follower}"
                    userQueue.on 'queueBindOk', =>
                        console.log("queue created - user_#{follower}")
    

start = (config)=>
    @connection = amqp.createConnection config

    @connection.on 'error', (e)->
      console.error "An error occured while AMQP connection! #{e.message}"

    @connection.on 'ready', =>
        console.log("Connection Ready")
        @connection.exchange 'activities', { type : 'direct', autoDelete : no, durable : yes, exclusive : no }, (activitiesExchange) =>
            # lets create a mil users
            for i in [1...max_user_count]
                user = {id:i, followees:[]}
                random = Math.floor(Math.random()* max_user_count)
                start_user_id = random-followee_count
                for f in [0..followee_count]
                    follower_id = start_user_id + f
                    if follower_id != i
                        user.followees.push(follower_id)
                createExchangeForUser(user)
                if i%1000==0
                    console.log(i)
            console.log("added users")


        
###

            # now create a follower
                
                    
                    # lets publish something to user_1 and see if it works....
                    activitiesExchange.publish("user_1", "hello")
                user_2_queue.subscribe (message)=>
                    console.log("message received", message)
###

###
    console.log("adding followers")
    cnt = 0
    for user_id of users    
        cnt++
        if cnt % 1000 == 0
            console.log(user_id)
        users[user_id].followees = randomFollowees(followee_count, user.id)
    console.log("added followers")
###






start KONFIG.mq
