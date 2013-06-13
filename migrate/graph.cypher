# change koding user name to timahong in JAccount
START koding=node:koding("id:*")
WHERE
koding.name = "JAccount" and
koding.`profile.nickname` = "koding"
SET koding.`profile.nickname` = "timahong";


# change koding user name to timahong in JUser
START koding=node:koding("id:*")
WHERE
koding.name = "JUser" and
koding.username = "koding"
SET koding.username = "timahong";


# set all users to offline
START koding=node:koding("id:*")
WHERE koding.name = "JAccount"
SET koding.onlineStatus = "offline";


# set all users to offline
START koding=node:koding("id:*")
WHERE koding.name = "JUser"
SET koding.`actual.onlineStatus` = "offline";

# add group property to all posts as koding
START kd=node:koding("id:*")
WHERE
kd.name = "JCodeShare" OR
kd.name = "JCodeSnip" OR
kd.name = "JDiscussion" OR
kd.name = "JInvitationRequest" OR
kd.name = "JOpinion" OR
kd.name = "JPost" OR
kd.name = "JStatusUpdate" OR
kd.name = "JTag" OR
kd.name = "JTutorial" OR
kd.name = "JTutorialList" OR
kd.name = "JBlogPost" OR
kd.name = "JVocabulary"
SET kd.group = "koding";


# set Jguest status to pristine
START koding=node:koding("id:*")
WHERE
koding.name = "JGuest"
SET koding.status = "pristine";


# 1) we need to update JUsers with u (uid)
# 2) we need to run migrator after 10m th relationship
