# Librato stats collector worker
#
# These values should be defined in config:
#
#   librato:
#     push: yes
#     email: "account@example.com"
#     token: "API_KEY"
#     interval: 5000
#   mango: "user:pass@server:port/path?options"

# Get configuration file
{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

{librato, mongo} = KONFIG

os = require 'os'
http = require 'http'

# Interval
interval = if librato?.interval? then librato.interval else 10000

# Node ID
node_id = os.hostname()

# Mongo entry counts
db_users = 0
db_activities = 0
db_mysql = 0
db_mongo = 0

# Mongo data collector
mongoskin = require 'mongoskin'

mongo += '?auto_reconnect'

db = mongoskin.db mongo

# Prints to console, if verbose mode is enabled
print = (msg) ->
  if argv.v
    console.log msg

# Collects stats
get_stats = ->
  # System load
  loadavg = os.loadavg()
  print "Load average: " + loadavg
  load1 =
    name: 'load'
    source: '1:' + node_id
    value: loadavg[0]
  load5 =
    name: 'load'
    source: '5:' + node_id
    value: loadavg[1]
  load15 =
    name: 'load'
    source: '15:' + node_id
    value: loadavg[2]

  # CPU usage
  cpu_usage = get_cpu_usage()
  print "CPU usage: " + cpu_usage
  cpu_total =
    name: 'cpu'
    source: node_id
    value: cpu_usage

  # Available memory
  mem_total = os.totalmem() / (1024 * 1024)
  mem_free = os.freemem() / (1024 * 1024)
  mem_used = mem_total - mem_free
  print "Memory: " + mem_used + "/" + mem_total
  memory_used =
    name: 'memory_used'
    source: node_id
    value: mem_used * 100 / mem_total

  # Mongo stats
  print "Users: " + db_users
  print "Activities: " + db_activities
  print "Mongo Databases: " + db_mongo
  print "MySQL Databases: " + db_mysql
  total_users =
    name: 'users'
    value: db_users
  total_activities =
    name: 'activities'
    value: db_activities
  total_mysql =
    name: 'database'
    source: 'mysql'
    value: db_mysql
  total_mongo =
    name: 'database'
    source: 'mongo'
    value: db_mongo
  
  # Combine all stats
  stats =
    gauges: [
      # Load average
      load1,
      load5,
      load15,
      # CPU usage
      cpu_total,
      # Memory
      memory_used,
      # Users
      total_users,
      # Activities
      total_activities,
      # Databases
      total_mysql,
      total_mongo
    ]
  print ""
  stats

get_cpu_usage = ->
  cpus = os.cpus()
  used = 0
  total = 0

  for i of cpus
    cpu = cpus[i]
    for type of cpu.times
      total += cpu.times[type]
      if type != 'idle'
        used += cpu.times[type]

  Math.floor 100 * used / total

# Pushes stats to Librato
push = (stats) ->
  if librato?.push
    client = require("librato-metrics").createClient(
      email: librato.email
      token: librato.token
    )
    client.post '/metrics', stats, (err, response) ->
      if err
        console.log "LIBRATO: " + err

# Collect stats and post to Librato
post_to_librato = ->
  data = get_stats()
  push data

# Collect information from Mongo
collect_mongo = ->
  # Get total users
  collector = db.collection 'jUsers'
  collector.count (err, count) ->
    db_users = count

  # Get total activities
  collector = db.collection 'cActivities'
  collector.count (err, count) ->
    db_activities = count

  # Get total MySQL databases
  collector = db.collection 'jDatabases'
  collector.count {type: 'JDatabaseMySql'}, (err, count) ->
    db_mysql = count

  # Get total Mongo databases
  collector = db.collection 'jDatabases'
  collector.count {type: 'JDatabaseMongo'}, (err, count) ->
    db_mongo = count

# Collect data from Mongo in every <interval>/2 seconds
setInterval ->
  collect_mongo()
, (interval / 2)

# Post to Librato in every <interval> seconds
setInterval ->
  post_to_librato()
, interval
