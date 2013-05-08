neo4j = require "neo4j"
db = new neo4j.GraphDatabase('http://localhost:7474');

  # name: 'JAccount',
  # name: 'JApp',
  # name: 'JAppStorage' }
  # name: 'JAppStorage',
  # name: 'JCodeSnip',
  # name: 'JComment',
  # name: 'JDiscussion',
  # name: 'JEmailConfirmation',
  # name: 'JInvitation',
  # name: 'JLimit' }
  # name: 'JOpinion',
  # name: 'JPrivateMessage',
  # name: 'JReview',
  # name: 'JStatusUpdate',
  # name: 'JTag',
  # name: 'JTutorial',
  # name: 'JUser',

query = [
  'start koding=node:koding(\'id:*\')'
  # 'match koding'
  'where koding.name = "JTutorial"'
  ' or koding.name = "JCodeSnip"' 
  ' or koding.name = "JDiscussion"' 
  ' or koding.name = "JStatusUpdate"' 
  'return koding'
  'order by koding.`meta.createdAt` DESC'
  'limit 10'  
].join('\n');


query = [
  'start koding=node:koding(\'id:*\')'
  'match koding-->all'
  'where koding.name = "JTutorial"'
  # ' or koding.name = "JCodeSnip"' 
  # ' or koding.name = "JDiscussion"' 
  # ' or koding.name = "JStatusUpdate"' 
  'return *'
  'order by koding.`meta.createdAt` DESC'
  'limit 4'  
].join('\n');

query = [
  'start koding=node:koding(\'id:*\')'
  'match koding-[r]->all'
  'where koding.name = "JTutorial"'
  'return type(r)'
  'limit 40'  
].join('\n');


params =
  tag : "*"
  className : "JAccount"


query = [
  'start koding=node:koding(id={itemId})'
  # 'match koding-[:like|author|tag|opinion|commenter|follower|author]->all'
  'match koding-[r]-all'
  'return *'
  'order by koding.`meta.createdAt` DESC'
].join('\n');

params =
  itemId : "515360d23af2fb6b6b000009"

start = new Date().getTime()

db.query query, params, (err, results) ->
  if err then throw err;
  # console.log results
  for result in results
    # console.log result.koding.data.length
    # console.log result.all.data
    console.log result.koding.data.id
    console.log result.r.type
    console.log result.all.data

  # koding = results.map (res) ->
  #   res['koding']

  # console.log koding
  # users = results.map (res) ->
  #   res['users']?.data

  # console.log koding.length
  # console.log new Date().getTime() - start
  # console.log koding


  # console.log users.length
  # console.log new Date().getTime() - start
  # console.log users

start activity=node:koding('id:*') return activity.`meta.createdAt` order by activity.`meta.createdAt` DESC limit 50
