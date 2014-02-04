var testUser = db.jUsers.findOne({username:"testuser1011"});

if (testUser) {
  print("'testuser101' already in database...existing.");
  return
}

print("Adding 'testuser101' to database.");

db.jUsers.insert({
  "_id" : ObjectId("52f1535428d687e77d001a4e"),
  "email" : "senthil+testuser@koding.com",
  "emailFrequency" : {
    "global" : true,
    "daily" : true,
    "privateMessage" : true,
    "followActions" : false,
    "comment" : true,
    "likeActivities" : false,
    "groupInvite" : true,
    "groupRequest" : true,
    "groupApproved" : true
  },
  "lastLoginDate" : ISODate("2014-02-04T20:53:40.692Z"),
  "oldUsername" : "guest-1913824",
  "onlineStatus" : {
    "actual" : "online"
  },
  "password" : "985d96c57e29d815fb21389ca3bbf55203e6782d",
  "passwordStatus" : "valid",
  "registeredAt" : ISODate("2014-02-04T20:53:40.692Z"),
  "salt" : "e949d97798352dfba6d344bbede5795c",
  "status" : "confirmed",
  "uid" : 2978889,
  "username" : "testuser101"
})

db.jAccounts.insert({
  "_id" : ObjectId("52f1535428d687e77d001a4f"),
  "counts" : {
    "followers" : 0,
    "following" : 0,
    "topics" : 0,
    "likes" : 0,
    "statusUpdates" : 0,
    "staffLikes" : 0,
    "comments" : 0,
    "referredUsers" : 0,
    "invitations" : 0,
    "lastLoginDate" : ISODate("2014-02-04T18:46:02.109Z"),
    "twitterFollowers" : 0
  },
  "isExempt" : false,
  "meta" : {
    "modifiedAt" : ISODate("2014-02-04T23:13:35.161Z"),
    "createdAt" : ISODate("2014-02-04T20:53:40.697Z"),
    "likes" : 0
  },
  "onlineStatus" : "online",
  "profile" : {
    "firstName" : "testuser101",
    "hash" : "f25e82dc364fe97185e20d75aadef8a8",
    "lastName" : "",
    "nickname" : "testuser101"
  },
  "systemInfo" : {
    "defaultToLastUsedEnvironment" : true
  },
  "type" : "registered"
})

db.relationships.insert({
  "timestamp" : ISODate("2014-02-04T20:18:38.351Z"),
  "targetId" : ObjectId("52f1535428d687e77d001a4f"),
  "targetName" : "JAccount",
  "sourceId" : ObjectId("52f1535428d687e77d001a4e"),
  "sourceName" : "JUser",
  "as" : "owner",
  "_id" : ObjectId("52f14b1ef0d45c000001017e")
})
