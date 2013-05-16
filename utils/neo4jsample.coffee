neo4j = require "neo4j"
# db = new neo4j.GraphDatabase('http://kgraphdb1.in.koding.com:7474');
db = new neo4j.GraphDatabase('http://neo4j-dev:7474');

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
  ' or koding.name = "JCodeSnip"'
  ' or koding.name = "JDiscussion"'
  ' or koding.name = "JStatusUpdate"'
  'return *'
  'order by koding.`meta.createdAt` DESC'
  'limit 4'
].join('\n');

query = [
  'start koding=node:koding(\'id:*\')'
  'match koding-[r:author]->all'
  'where koding.name = "JTutorial"'
  ' or koding.name = "JCodeSnip"'
  ' or koding.name = "JDiscussion"'
  ' or koding.name = "JStatusUpdate"'
  'return type(r)'
  'limit 400'
].join('\n');


params =
  tag : "*"
  className : "JAccount"


query = [
  # 'start  koding=node:koding(id={groupId})'
  'start koding=node:koding(\'id:*\')'
  'MATCH  koding-[:member]->members-[r]-content'
  # 'MATCH  koding-[:author]-content'
  # 'where  members.name="JAccount" and r.createdAt > {startDate} and r.createdAt < {endDate}'
  # ' where content.name = "JTutorial"'
  # ' or content.name = "JCodeSnip"'
  # ' or content.name = "JDiscussion"'
  # ' or content.name = "JStatusUpdate"'
  'return *'
  # 'order by koding.`meta.createdAt` DESC'
  'limit 10'
].join('\n');

params =
  groupId : "5150c743f2589b107d000007"

start = new Date().getTime()

db.query query, params, (err, results) ->
  if err then throw err;
  # console.log results
  for result in results
    console.log result.members.data
    console.log result.content.data
    console.log result.r.type
    # console.log result

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

# start activity=node:koding('id:*') return activity.`meta.createdAt` order by activity.`meta.createdAt` DESC limit 50
