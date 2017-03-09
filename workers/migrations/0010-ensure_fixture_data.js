var mongodb = require('mongodb');
var async = require('async');
var ObjectId = mongodb.ObjectID;

var data = {
  "relationships": [
    {
      "_id": ObjectId("5196fcb0bc9bdb000000001e"),
      "timestamp": new Date("2013-05-18T03:59:44.971Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000011"),
      "targetName": "JAccount",
      "sourceId": ObjectId("5196fcb0bc9bdb0000000009"),
      "sourceName": "JUser",
      "as": "owner"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb0000000028"),
      "timestamp": new Date("2013-05-18T03:59:46.184Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000011"),
      "targetName": "JAccount",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "member"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb0000000029"),
      "timestamp": new Date("2013-05-18T03:59:46.188Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000011"),
      "targetName": "JAccount",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "admin"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb000000002a"),
      "timestamp": new Date("2013-05-18T03:59:46.218Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000011"),
      "targetName": "JAccount",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "owner"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb000000002e"),
      "timestamp": new Date("2013-05-18T03:59:46.348Z"),
      "targetId": ObjectId("5196fcb2bc9bdb000000002c"),
      "targetName": "JPermissionSet",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "defaultpermset"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb000000002f"),
      "timestamp": new Date("2013-05-18T03:59:46.359Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000019"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "role"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb0000000030"),
      "timestamp": new Date("2013-05-18T03:59:46.361Z"),
      "targetId": ObjectId("5196fcb0bc9bdb000000001a"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "role"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb0000000031"),
      "timestamp": new Date("2013-05-18T03:59:46.362Z"),
      "targetId": ObjectId("5196fcb0bc9bdb000000001b"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "role"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb0000000032"),
      "timestamp": new Date("2013-05-18T03:59:46.364Z"),
      "targetId": ObjectId("5196fcb0bc9bdb000000001c"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "role"
    },
    {
      "_id": ObjectId("5196fcb2bc9bdb0000000033"),
      "timestamp": new Date("2013-05-18T03:59:46.366Z"),
      "targetId": ObjectId("5196fcb0bc9bdb000000001d"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "role"
    },
    {
      "_id": ObjectId("539f486cd46c2000003e7374"),
      "data": {},
      "timestamp": new Date("2014-06-16T19:41:32.458Z"),
      "targetId": ObjectId("539f486cd46c2000003e7373"),
      "targetName": "JPermissionSet",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "permset"
    },
    {
      "_id": ObjectId("54e66edec9b8971297d83c8f"),
      "as": "owner",
      "data": {},
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "targetId": ObjectId("51d5bda6bc698b560a000007"),
      "targetName": "JMembershipPolicy",
      "timestamp": new Date("2015-01-18T19:57:02.879Z")
    },
    {
      "_id": ObjectId("54eb1e6228f392b018969ddd"),
      "data": {},
      "timestamp": new Date("2015-02-23T12:34:42.002Z"),
      "targetId": ObjectId("54eb1e6128f392b018969ddc"),
      "targetName": "JAccount",
      "sourceId": ObjectId("54eb1e6128f392b018969ddb"),
      "sourceName": "JUser",
      "as": "owner"
    },
    {
      "_id": ObjectId("54eb1e6228f392b018969ddf"),
      "data": {},
      "timestamp": new Date("2015-02-23T12:34:42.036Z"),
      "targetId": ObjectId("54eb1e6128f392b018969ddc"),
      "targetName": "JAccount",
      "sourceId": ObjectId("5196fcb2bc9bdb0000000027"),
      "sourceName": "JGroup",
      "as": "member"
    },
    {
      "_id": ObjectId("54eb1e6228f392b018969de1"),
      "data": {},
      "timestamp": new Date("2015-02-23T12:34:42.068Z"),
      "targetId": ObjectId("53925a609b76835748c0c4fd"),
      "targetName": "JStackTemplate",
      "sourceId": ObjectId("54eb1e6128f392b018969ddc"),
      "sourceName": "JAccount",
      "as": "user"
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.197Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000011"),
      "targetName": "JAccount",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "member",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b499")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.200Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000011"),
      "targetName": "JAccount",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "admin",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b49a")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.200Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000011"),
      "targetName": "JAccount",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "owner",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b49b")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.207Z"),
      "targetId": ObjectId("57f85c0ff8578ae3d9d8b49c"),
      "targetName": "JPermissionSet",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "defaultpermset",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b49d")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.210Z"),
      "targetId": ObjectId("5196fcb0bc9bdb0000000019"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "role",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b49e")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.210Z"),
      "targetId": ObjectId("5196fcb0bc9bdb000000001a"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "role",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b49f")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.211Z"),
      "targetId": ObjectId("5196fcb0bc9bdb000000001b"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "role",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b4a0")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.211Z"),
      "targetId": ObjectId("5196fcb0bc9bdb000000001c"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "role",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b4a1")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.211Z"),
      "targetId": ObjectId("5196fcb0bc9bdb000000001d"),
      "targetName": "JGroupRole",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "role",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b4a2")
    },
    {
      "data": {},
      "timestamp": new Date("2016-10-08T02:38:07.380Z"),
      "targetId": ObjectId("57f85c0ff8578ae3d9d8b4a3"),
      "targetName": "JMembershipPolicy",
      "sourceId": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "sourceName": "JGroup",
      "as": "owner",
      "_id": ObjectId("57f85c0ff8578ae3d9d8b4a4")
    }
  ],
  "jUsers": [
    {
      "_id": ObjectId("5196fcb0bc9bdb0000000009"),
      "email": "root@localhost",
      "emailFrequency": {
        "global": false,
        "daily": false,
        "privateMessage": false,
        "followActions": false,
        "comment": false,
        "likeActivities": false,
        "groupInvite": true
      },
      "globalFlags": [
        "super-admin"
      ],
      "lastLoginDate": new Date("2016-10-08T02:38:07.179Z"),
      "onlineStatus": {
        "actual": "online"
      },
      "password": "c1ef3f51979f497ac87ea460e4f6582be9d9417a",
      "registeredAt": new Date("2013-05-18T03:59:44.745Z"),
      "salt": "9cdca15921eb5c9fa9cd6660f653758d",
      "sanitizedEmail": "root@localhost",
      "status": "confirmed",
      "uid": 1000000,
      "username": "admin"
    },
    {
      "_id": ObjectId("54eb1e6128f392b018969ddb"),
      "email": "guestuser@koding.com",
      "emailFrequency": {
        "global": true,
        "daily": true,
        "privateMessage": true,
        "followActions": false,
        "comment": true,
        "likeActivities": false,
        "groupInvite": true,
        "groupRequest": true,
        "groupApproved": true,
        "groupJoined": true,
        "groupLeft": false,
        "mention": true,
        "marketing": true
      },
      "lastLoginDate": new Date("2015-02-23T12:34:41.983Z"),
      "onlineStatus": {
        "actual": "online"
      },
      "password": "b89b59f14a19a4673afab065a532ad401ac49281",
      "passwordStatus": "valid",
      "registeredAt": new Date("2015-02-23T12:34:41.983Z"),
      "salt": "d91387b84d9975faf7d8a6e233dc287c",
      "sanitizedEmail": "guestuser@koding.com",
      "status": "confirmed",
      "uid": null,
      "username": "guestuser"
    },
    {
      "_id": ObjectId("567a731b8be4fe61ca000002"),
      "blockedReason": "",
      "email": "bot@koding.com",
      "emailFrequency": {
        "global": false,
        "daily": false,
        "privateMessage": false,
        "followActions": false,
        "comment": false,
        "likeActivities": false,
        "groupInvite": false,
        "groupRequest": false,
        "groupApproved": false,
        "groupJoined": false,
        "groupLeft": false,
        "mention": false,
        "pmNotificationDelay": ""
      },
      "foreignAuth": {
        "github": {
          "token": "",
          "email": "",
          "username": "",
          "scope": ""
        }
      },
      "oldUsername": "",
      "password": "bot",
      "salt": "bot",
      "sanitizedEmail": "bot@koding.com",
      "shell": "",
      "sshKeys": [],
      "status": "",
      "uid": 0,
      "username": "bot"
    }
  ],
  "jStackTemplates": [
    {
      "_id": ObjectId("53925a609b76835748c0c4fd"),
      "meta": {
        "modifiedAt": new Date("2014-05-15T02:04:11.033Z"),
        "createdAt": new Date("2014-05-15T02:04:11.032Z"),
        "likes": 0
      },
      "accessLevel": "private",
      "title": "Default stack",
      "description": "Koding's default stack template for new users",
      "config": {
        "groupStack": true
      },
      "rules": [],
      "domains": [],
      "machines": [
        {
          "label": "koding-vm-0",
          "provider": "koding",
          "instanceType": "t2.nano",
          "provisioners": [],
          "region": "us-east-1",
          "source_ami": "ami-a6926dce"
        }
      ],
      "extras": [],
      "connections": [],
      "group": "koding",
      "originId": ObjectId("5196fcb0bc9bdb0000000011")
    }
  ],
  "jSecretNames": [
    {
      "_id": ObjectId("5397b4d5d582a63b515e1669"),
      "secretName": "176d187f83b108822312429bb7254b1b",
      "name": "koding"
    }
  ],
  "jRegistrationPreferences": [
    {
      "_id": ObjectId("5197c70455b5b19b73ff844f"),
      "isRegistrationEnabled": true
    }
  ],
  "jPermissionSets": [
    {
      "_id": ObjectId("5196fcb2bc9bdb000000002c"),
      "isCustom": true,
      "permissions": [
        {
          "module": "JGroup",
          "role": "member",
          "permissions": [
            "open group",
            "list members",
            "read group activity",
            "edit own groups",
            "query collection",
            "view readme",
            "read posts",
            "create posts",
            "edit own posts",
            "delete own posts",
            "reply to posts",
            "like posts",
            "pin posts",
            "send private message",
            "list private messages",
            "delete own channel",
            "delete channel",
            "read tags",
            "create tags",
            "freetag content",
            "browse content by tag"
          ]
        },
        {
          "module": "JGroup",
          "role": "moderator",
          "permissions": [
            "open group",
            "list members",
            "read group activity",
            "create groups",
            "edit groups",
            "edit own groups",
            "query collection",
            "update collection",
            "assure collection",
            "remove documents from collection",
            "view readme",
            "send invitations",
            "read posts",
            "create posts",
            "edit posts",
            "delete posts",
            "edit own posts",
            "delete own posts",
            "reply to posts",
            "like posts",
            "pin posts",
            "send private message",
            "list private messages",
            "delete channel",
            "read tags",
            "create tags",
            "freetag content",
            "browse content by tag",
            "edit tags",
            "delete tags",
            "edit own tags",
            "delete own tags",
            "assign system tag",
            "fetch system tag",
            "create system tag",
            "remove system tag",
            "create synonym tags"
          ]
        },
        {
          "module": "JGroup",
          "role": "guest",
          "permissions": [
            "read group activity"
          ]
        },
        {
          "module": "JKite",
          "role": "member",
          "permissions": [
            "create kite",
            "list kites"
          ]
        },
        {
          "module": "JMachine",
          "role": "member",
          "permissions": [
            "list machines",
            "populate users",
            "set provisioner",
            "set domain",
            "set label"
          ]
        },
        {
          "module": "ComputeProvider",
          "role": "member",
          "permissions": [
            "ping machines",
            "list machines",
            "create machines",
            "delete machines",
            "update machines",
            "list own machines"
          ]
        },
        {
          "module": "ComputeProvider",
          "role": "moderator",
          "permissions": [
            "ping machines",
            "list machines",
            "create machines",
            "delete machines",
            "update machines",
            "list own machines"
          ]
        },
        {
          "module": "JInvitation",
          "role": "member",
          "permissions": [
            "send invitations",
            "remove invitation"
          ]
        },
        {
          "module": "JCredential",
          "role": "member",
          "permissions": [
            "create credential",
            "update credential",
            "list credentials",
            "delete credential"
          ]
        },
        {
          "module": "JProvisioner",
          "role": "member",
          "permissions": [
            "create provisioner",
            "list provisioners",
            "update own provisioner",
            "delete own provisioner"
          ]
        },
        {
          "module": "JSnapshot",
          "role": "member",
          "permissions": [
            "list snapshots",
            "update snapshot"
          ]
        },
        {
          "module": "JStackTemplate",
          "role": "member",
          "permissions": [
            "create stack template",
            "list stack templates",
            "delete own stack template",
            "update own stack template",
            "check own stack usage"
          ]
        },
        {
          "module": "JStackTemplate",
          "role": "moderator",
          "permissions": [
            "create stack template",
            "list stack templates",
            "delete own stack template",
            "update own stack template"
          ]
        },
        {
          "module": "JProposedDomain",
          "role": "member",
          "permissions": [
            "create domains",
            "edit domains",
            "edit own domains",
            "delete domains",
            "delete own domains",
            "list domains"
          ]
        },
        {
          "module": "JDomainAlias",
          "role": "member",
          "permissions": [
            "list domains"
          ]
        },
        {
          "module": "Github",
          "role": "member",
          "permissions": [
            "api access"
          ]
        },
        {
          "module": "Github",
          "role": "moderator",
          "permissions": [
            "api access"
          ]
        },
        {
          "module": "GitProvider",
          "role": "member",
          "permissions": [
            "import stack template"
          ]
        },
        {
          "module": "SocialNotification",
          "role": "member",
          "permissions": [
            "list notifications"
          ]
        },
        {
          "module": "SocialNotification",
          "role": "moderator",
          "permissions": [
            "list notifications"
          ]
        },
        {
          "module": "JComputeStack",
          "role": "member",
          "permissions": [
            "create stack",
            "update own stack",
            "delete own stack",
            "list stacks"
          ]
        }
      ]
    },
    {
      "_id": ObjectId("539f486cd46c2000003e7373"),
      "isCustom": true,
      "permissions": [
        {
          "module": "JGroup",
          "role": "member",
          "permissions": [
            "open group",
            "list members",
            "read group activity",
            "edit own groups",
            "query collection",
            "view readme",
            "read posts",
            "create posts",
            "edit own posts",
            "delete own posts",
            "reply to posts",
            "like posts",
            "pin posts",
            "send private message",
            "list private messages",
            "delete own channel",
            "delete channel",
            "read tags",
            "create tags",
            "freetag content",
            "browse content by tag"
          ]
        },
        {
          "module": "JGroup",
          "role": "moderator",
          "permissions": [
            "open group",
            "list members",
            "read group activity",
            "create groups",
            "edit groups",
            "edit own groups",
            "query collection",
            "update collection",
            "assure collection",
            "remove documents from collection",
            "view readme",
            "send invitations",
            "read posts",
            "create posts",
            "edit posts",
            "delete posts",
            "edit own posts",
            "delete own posts",
            "reply to posts",
            "like posts",
            "pin posts",
            "send private message",
            "list private messages",
            "delete channel",
            "read tags",
            "create tags",
            "freetag content",
            "browse content by tag",
            "edit tags",
            "delete tags",
            "edit own tags",
            "delete own tags",
            "assign system tag",
            "fetch system tag",
            "create system tag",
            "remove system tag",
            "create synonym tags"
          ]
        },
        {
          "module": "JGroup",
          "role": "guest",
          "permissions": [
            "read group activity"
          ]
        },
        {
          "module": "JKite",
          "role": "member",
          "permissions": [
            "create kite",
            "list kites"
          ]
        },
        {
          "module": "JMachine",
          "role": "member",
          "permissions": [
            "list machines",
            "populate users",
            "set provisioner",
            "set domain",
            "set label"
          ]
        },
        {
          "module": "ComputeProvider",
          "role": "member",
          "permissions": [
            "ping machines",
            "list machines",
            "create machines",
            "delete machines",
            "update machines",
            "list own machines"
          ]
        },
        {
          "module": "ComputeProvider",
          "role": "moderator",
          "permissions": [
            "ping machines",
            "list machines",
            "create machines",
            "delete machines",
            "update machines",
            "list own machines"
          ]
        },
        {
          "module": "JInvitation",
          "role": "member",
          "permissions": [
            "send invitations",
            "remove invitation"
          ]
        },
        {
          "module": "JCredential",
          "role": "member",
          "permissions": [
            "create credential",
            "update credential",
            "list credentials",
            "delete credential"
          ]
        },
        {
          "module": "JProvisioner",
          "role": "member",
          "permissions": [
            "create provisioner",
            "list provisioners",
            "update own provisioner",
            "delete own provisioner"
          ]
        },
        {
          "module": "JSnapshot",
          "role": "member",
          "permissions": [
            "list snapshots",
            "update snapshot"
          ]
        },
        {
          "module": "JStackTemplate",
          "role": "member",
          "permissions": [
            "create stack template",
            "list stack templates",
            "delete own stack template",
            "update own stack template",
            "check own stack usage"
          ]
        },
        {
          "module": "JStackTemplate",
          "role": "moderator",
          "permissions": [
            "create stack template",
            "list stack templates",
            "delete own stack template",
            "update own stack template"
          ]
        },
        {
          "module": "JProposedDomain",
          "role": "member",
          "permissions": [
            "create domains",
            "edit domains",
            "edit own domains",
            "delete domains",
            "delete own domains",
            "list domains"
          ]
        },
        {
          "module": "JDomainAlias",
          "role": "member",
          "permissions": [
            "list domains"
          ]
        },
        {
          "module": "Github",
          "role": "member",
          "permissions": [
            "api access"
          ]
        },
        {
          "module": "Github",
          "role": "moderator",
          "permissions": [
            "api access"
          ]
        },
        {
          "module": "GitProvider",
          "role": "member",
          "permissions": [
            "import stack template"
          ]
        },
        {
          "module": "SocialNotification",
          "role": "member",
          "permissions": [
            "list notifications"
          ]
        },
        {
          "module": "SocialNotification",
          "role": "moderator",
          "permissions": [
            "list notifications"
          ]
        },
        {
          "module": "JComputeStack",
          "role": "member",
          "permissions": [
            "create stack",
            "update own stack",
            "delete own stack",
            "list stacks"
          ]
        }
      ]
    },
    {
      "_id" : ObjectId("57f85c0ff8578ae3d9d8b49c"),
      "isCustom": null,
      "permissions": [
        {
          "module": "JGroup",
          "role": "member",
          "permissions": [
            "open group",
            "list members",
            "read group activity",
            "edit own groups",
            "query collection",
            "view readme",
            "read posts",
            "create posts",
            "edit own posts",
            "delete own posts",
            "reply to posts",
            "like posts",
            "pin posts",
            "send private message",
            "list private messages",
            "delete own channel",
            "delete channel",
            "read tags",
            "create tags",
            "freetag content",
            "browse content by tag"
          ]
        },
        {
          "module": "JGroup",
          "role": "moderator",
          "permissions": [
            "open group",
            "list members",
            "read group activity",
            "create groups",
            "edit groups",
            "edit own groups",
            "query collection",
            "update collection",
            "assure collection",
            "remove documents from collection",
            "view readme",
            "send invitations",
            "read posts",
            "create posts",
            "edit posts",
            "delete posts",
            "edit own posts",
            "delete own posts",
            "reply to posts",
            "like posts",
            "pin posts",
            "send private message",
            "list private messages",
            "delete channel",
            "read tags",
            "create tags",
            "freetag content",
            "browse content by tag",
            "edit tags",
            "delete tags",
            "edit own tags",
            "delete own tags",
            "assign system tag",
            "fetch system tag",
            "create system tag",
            "remove system tag",
            "create synonym tags"
          ]
        },
        {
          "module": "JKite",
          "role": "member",
          "permissions": [
            "create kite",
            "list kites"
          ]
        },
        {
          "module": "JMachine",
          "role": "member",
          "permissions": [
            "list machines",
            "populate users",
            "set provisioner",
            "set domain",
            "set label"
          ]
        },
        {
          "module": "ComputeProvider",
          "role": "member",
          "permissions": [
            "ping machines",
            "list machines",
            "create machines",
            "delete machines",
            "update machines",
            "list own machines"
          ]
        },
        {
          "module": "ComputeProvider",
          "role": "moderator",
          "permissions": [
            "ping machines",
            "list machines",
            "create machines",
            "delete machines",
            "update machines",
            "list own machines"
          ]
        },
        {
          "module": "JInvitation",
          "role": "member",
          "permissions": [
            "send invitations",
            "remove invitation"
          ]
        },
        {
          "module": "JCredential",
          "role": "member",
          "permissions": [
            "create credential",
            "update credential",
            "list credentials",
            "delete credential"
          ]
        },
        {
          "module": "JProvisioner",
          "role": "member",
          "permissions": [
            "create provisioner",
            "list provisioners",
            "update own provisioner",
            "delete own provisioner"
          ]
        },
        {
          "module": "JSnapshot",
          "role": "member",
          "permissions": [
            "list snapshots",
            "update snapshot"
          ]
        },
        {
          "module": "JStackTemplate",
          "role": "member",
          "permissions": [
            "create stack template",
            "list stack templates",
            "delete own stack template",
            "update own stack template",
            "check own stack usage"
          ]
        },
        {
          "module": "JStackTemplate",
          "role": "moderator",
          "permissions": [
            "create stack template",
            "list stack templates",
            "delete own stack template",
            "update own stack template"
          ]
        },
        {
          "module": "JProposedDomain",
          "role": "member",
          "permissions": [
            "create domains",
            "edit domains",
            "edit own domains",
            "delete domains",
            "delete own domains",
            "list domains"
          ]
        },
        {
          "module": "JDomainAlias",
          "role": "member",
          "permissions": [
            "list domains"
          ]
        },
        {
          "module": "Github",
          "role": "member",
          "permissions": [
            "api access"
          ]
        },
        {
          "module": "Github",
          "role": "moderator",
          "permissions": [
            "api access"
          ]
        },
        {
          "module": "GitProvider",
          "role": "member",
          "permissions": [
            "import stack template"
          ]
        },
        {
          "module": "SocialNotification",
          "role": "member",
          "permissions": [
            "list notifications"
          ]
        },
        {
          "module": "SocialNotification",
          "role": "moderator",
          "permissions": [
            "list notifications"
          ]
        },
        {
          "module": "JComputeStack",
          "role": "member",
          "permissions": [
            "create stack",
            "update own stack",
            "delete own stack",
            "list stacks"
          ]
        }
      ]
    }
  ],
  "jNames": [
    {
      "_id": ObjectId("5196fcb0bc9bdb0000000001"),
      "name": "admin",
      "slugs": [
        {
          "slug": "admin",
          "constructorName": "JUser",
          "usedAsPath": "username",
          "collectionName": "jUsers"
        }
      ]
    },
    {
      "_id": ObjectId("5196fcb1bc9bdb0000000026"),
      "name": "koding",
      "slugs": [
        {
          "slug": "koding",
          "constructorName": "JGroup",
          "usedAsPath": "slug",
          "collectionName": "jGroups"
        }
      ]
    },
    {
      "_id": ObjectId("51defdb73ed22b2905000022"),
      "name": "guests",
      "slugs": [
        {
          "slug": "guests",
          "constructorName": "JGroup",
          "usedAsPath": "slug",
          "collectionName": "jGroups"
        }
      ]
    },
    {
      "_id": ObjectId("54eb1e6128f392b018969dda"),
      "name": "guestuser",
      "slugs": [
        {
          "slug": "guestuser",
          "constructorName": "JUser",
          "usedAsPath": "username",
          "collectionName": "jUsers"
        }
      ]
    },
    {
      "name": "ide",
      "slugs": [
        {
          "slug": "ide",
          "constructorName": "JGroup",
          "usedAsPath": "slug",
          "group": null,
          "collectionName": "jGroups"
        }
      ],
      "_id": ObjectId("57f85c0ff8578ae3d9d8b497")
    }
  ],
  "jMembershipPolicies": [
    {
      "_id": ObjectId("51d5bda6bc698b560a000007"),
      "approvalEnabled": false,
      "dataCollectionEnabled": false
    },
    {
      "approvalEnabled": true,
      "dataCollectionEnabled": false,
      "_id": ObjectId("57f85c0ff8578ae3d9d8b4a3")
    }
  ],
  "jGroups": [
    {
      "_id": ObjectId("5196fcb2bc9bdb0000000027"),
      "body": "Modern Dev Environment Delivered · Koding",
      "counts": {
        "members": 3
      },
      "customize": {
        "background": {
          "customType": "defaultImage",
          "customValue": "1"
        }
      },
      "migration": "completed",
      "parent": [],
      "privacy": "private",
      "slug": "koding",
      "socialApiChannelId": "6190337717964898305",
      "stackTemplates": [
        "53925a609b76835748c0c4fd"
      ],
      "title": "Koding",
      "visibility": "visible"
    },
    {
      "_id": ObjectId("51defdb73ed22b2905000023"),
      "body": "",
      "counts": {
        "members": 6
      },
      "customize": {
        "background": {
          "customType": "defaultImage",
          "customValue": "1"
        }
      },
      "parent": {},
      "privacy": "public",
      "slug": "guests",
      "title": "Koding guests",
      "visibility": "visible",
      "migration": "failed",
      "error": "not found"
    },
    {
      "_id": ObjectId("57f85c0ff8578ae3d9d8b498"),
      "allowedDomains": [],
      "privacy": "private",
      "slug": "ide",
      "title": "ide",
      "visibility": "hidden"
    }
  ],
  "jGroupRoles": [
    {
      "_id": ObjectId("5196fcb0bc9bdb0000000019"),
      "isConfigureable": false,
      "isDefault": true,
      "title": "owner"
    },
    {
      "_id": ObjectId("5196fcb0bc9bdb000000001a"),
      "isConfigureable": false,
      "isDefault": true,
      "title": "admin"
    },
    {
      "_id": ObjectId("5196fcb0bc9bdb000000001b"),
      "isConfigureable": "true",
      "isDefault": true,
      "title": "moderator"
    },
    {
      "_id": ObjectId("5196fcb0bc9bdb000000001c"),
      "isConfigureable": false,
      "isDefault": true,
      "title": "member"
    },
    {
      "_id": ObjectId("5196fcb0bc9bdb000000001d"),
      "isConfigureable": false,
      "isDefault": true,
      "title": "guest"
    }
  ],
  "jDomainAliases": [
    {
      "createdAt": new Date("2016-07-20T19:10:53.258Z"),
      "machineId": ObjectId("578fccbdafa5c44a4cd37144"),
      "domain": "admin.dev.koding.io",
      "originId": ObjectId("578fccbdafa5c44a4cd3713e"),
      "_id": ObjectId("578fccbdafa5c44a4cd37145")
    }
  ],
  "jComputeStacks": [
    {
      "_id": ObjectId("578fccbdafa5c44a4cd37143"),
      "baseStackId": "53925a609b76835748c0c4fd",
      "config": {
        "groupStack": true
      },
      "credentials": null,
      "group": "koding",
      "machines": [
        ObjectId("578fccbdafa5c44a4cd37144")
      ],
      "meta": {
        "createdAt": new Date("2016-07-20T19:10:53.219Z"),
        "modifiedAt": new Date("2016-07-20T19:10:53.219Z"),
        "tags": null,
        "views": null,
        "votes": null,
        "likes": 0
      },
      "originId": ObjectId("578fccbdafa5c44a4cd3713e"),
      "stackRevision": "",
      "status": {
        "state": "NotInitialized"
      },
      "title": "Default stack"
    }
  ],
  "jAccounts": [
    {
      "_id": ObjectId("5196fcb0bc9bdb0000000011"),
      "counts": {
        "comments": 0,
        "followers": 0,
        "following": 0,
        "invitations": 0,
        "lastLoginDate": new Date("2016-10-08T02:38:07.179Z"),
        "likes": 0,
        "referredUsers": 0,
        "staffLikes": 0,
        "statusUpdates": 0,
        "topics": 0
      },
      "globalFlags": [
        "super-admin"
      ],
      "lastLoginTimezoneOffset": 420,
      "meta": {
        "modifiedAt": new Date("2014-06-11T00:01:48.675Z"),
        "createdAt": new Date("2013-05-18T03:59:44.831Z"),
        "likes": 0
      },
      "migration": "completed",
      "onlineStatus": "online",
      "profile": {
        "nickname": "admin",
        "firstName": "Koding",
        "lastName": "Admin",
        "hash": "b1a4b2518dbbdd47dd4a713d5cd1df94"
      },
      "socialApiId": "223",
      "systemInfo": {
        "defaultToLastUsedEnvironment": true
      },
      "type": "registered"
    },
    {
      "_id": ObjectId("54eb1e6128f392b018969ddc"),
      "counts": {
        "followers": 0,
        "following": 0,
        "topics": 0,
        "likes": 0
      },
      "error": "guests are not allowed",
      "isExempt": false,
      "meta": {
        "modifiedAt": new Date("2015-02-23T12:34:41.993Z"),
        "createdAt": new Date("2015-02-23T12:34:41.992Z"),
        "tags": null,
        "views": null,
        "votes": null,
        "likes": 0
      },
      "migration": "failed",
      "onlineStatus": "online",
      "profile": {
        "nickname": "guestuser",
        "hash": "c5a4efb1d63e5042758bcca5625b74e6",
        "firstName": "Guest",
        "lastName": "User"
      },
      "socialApiId": 0.0,
      "systemInfo": {
        "defaultToLastUsedEnvironment": true
      },
      "type": "unregistered"
    },
    {
      "_id": ObjectId("567a731b8be4fe61ca000001"),
      "globalFlags": [],
      "isExempt": false,
      "lastLoginTimezoneOffset": 0,
      "meta": {
        "likes": 0
      },
      "onlineStatus": false,
      "profile": {
        "nickname": "bot",
        "firstName": "",
        "lastName": "",
        "hash": ""
      },
      "socialApiId": "224",
      "status": "",
      "systeminfo": {
        "defaultToLastUsedEnvironment": false
      },
      "type": ""
    }
  ],
  "counters": [
    {
      "_id": "guest",
      "seq": 1
    }
  ]
}

exports.up = function(db, next){
  var env = process.env.KONFIG_ENVIRONMENT;
  if (env !== "dev" && env !== "default") {
    return next();
  }

  async.eachOfSeries(data, function (items, collName, cb) {
      coll = db.collection(collName);
      async.eachOfLimit(items, 4, function (item, i, callback) {
          coll.findOne({ '_id': item._id }, function(err, data){
            if (!data) {
              coll.insert(item, callback);
            } else {
              callback();
            }
          });
      }, cb);
  }, next);
};

exports.down = function(db, next){
    next();
};
