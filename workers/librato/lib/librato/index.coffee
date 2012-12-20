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

# Parse arguments and get configuration file
{argv} = require 'optimist'
KONFIG = require argv.c.trim()
{librato, mongo} = KONFIG

os = require 'os'

# Mongo entry counts
db_users = 0
db_activities = 0

# Mongo data collector
mongoskin = require 'mongoskin'
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
    source: '1'
    value: loadavg[0]
  load5 =
    name: 'load'
    source: '5'
    value: loadavg[1]
  load15 =
    name: 'load'
    source: '15'
    value: loadavg[2]

  # Available memory
  mem_total = os.totalmem() / (1024 * 1024)
  mem_free = os.freemem() / (1024 * 1024)
  mem_used = mem_total - mem_free
  print "Memory: " + mem_used + "/" + mem_total
  memory_total =
    name: 'memory_total'
    value: mem_total
  memory_used =
    name: 'memory_used'
    value: mem_used

  # Mongo stats
  print "Users: " + db_users
  print "Activities: " + db_activities
  total_users =
    name: 'users'
    value: db_users
  total_activities =
    name: 'activities'
    value: db_activities
  
  # Combine all stats
  stats =
    gauges: [
      # Load average
      load1,
      load5,
      load15,
      # Memory
      memory_total,
      memory_used,
      # Users
      total_users,
      # Activities
      total_activities
    ]
  print ""
  stats

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

console.log "Starting Librato worker"

# Collect data from Mongo in every <interval>/2 seconds
setInterval ->
  # Get total users
  collector = db.collection 'jUsers'
  collector.count (err, count) ->
    db_users = count

  # # Get total posts
  # collector = db.collection 'jPosts'
  # collector.count (err, count) ->
  #   db_posts = count

  # Get total activities
  collector = db.collection 'cActivities'
  collector.count (err, count) ->
    db_activities = count

, (librato.interval / 2)

# Post to Librato in every <interval> seconds
setInterval ->
  data = get_stats()
  push data

, librato.interval
