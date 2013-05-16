neo4j = require "neo4j"
db = new neo4j.GraphDatabase('http://kgraphdb1.in.koding.com:7474');
# db = new neo4j.GraphDatabase('http://neo4j-dev:7474');

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
  'start koding=node:koding(\'id:5150c743f2589b107d000007\')'
  'MATCH  koding-[:member]->members<-[:author]-content'
  # 'where  members.name="JAccount" and r.createdAt > {startDate} and r.createdAt < {endDate}'
  # ' where content.name = "JTutorial"'
  # ' or content.name = "JCodeSnip"'
  # ' or content.name = "JDiscussion"'
  # ' or content.name = "JStatusUpdate"'
  'return *'
  # 'order by koding.`meta.createdAt` DESC'
  'limit 10'
].join('\n');
console.log query
# query = [
#   'start koding=node:koding(\'id:*\')'
#   'where koding.name = "JTutorial"'
#   ' or koding.name = "JCodeSnip"'
#   ' or koding.name = "JDiscussion"'
#   ' or koding.name = "JBlogPost"'
#   ' or koding.name = "JStatusUpdate"'
#   ' and has(koding.`meta.createdAt`)'
#   ' and koding.`meta.createdAt` < {startDate}'
#   'return *'
#   'order by koding.`meta.createdAt` DESC'
#   'limit 10'
# ].join('\n');


groupId : "5150c743f2589b107d000007"

query = [
  # 'start koding=node:koding(\'id:5150c743f2589b107d000007\')'
  'START koding=node:koding(id={groupId})'
  'MATCH koding-[:member]->members<-[:author]-content'
  'WHERE koding.name = "JTutorial"'
  ' or content.name = "JCodeSnip"'
  ' or content.name = "JDiscussion"'
  ' or content.name = "JBlogPost"'
  ' or content.name = "JStatusUpdate"'
  ' and has(content.`meta.createdAt`)'
  ' and koding.`meta.createdAt` < {startDate}'
  'return *'
  'order by content.`meta.createdAt` DESC'
  'limit 10'
].join('\n');

params =
  groupId   : "5150c743f2589b107d000007"
  startDate : "2013-05-15T22:06:38Z"


db.query query, params, (err, results) ->
  if err then throw err;
  for result in results
    console.log result.content.data
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
