module.exports = {
  "accessLevel":"private",
  "originId":"57043a0bd37cef1a22a5c427",
  "inUse":true,
  "config":{
    "requiredData":{
      "user":["username"],
      "group":["slug"],
      "custom":["foo"]
    },
    "requiredProviders":["aws","koding","custom"],
    "verified":true
  },
  "meta":{
    "data":{
      "createdAt":"2016-04-05T23:30:14.086Z",
      "modifiedAt":"2016-04-05T23:32:32.714Z",
      "likes":0
    },
    "createdAt":"2016-04-05T23:30:14.086Z",
    "modifiedAt":"2016-04-05T23:32:32.714Z",
    "likes":0
  },
  "machines":[{
    "label":"example_1",
    "provider":"aws",
    "region":"us-east-1",
    "source_ami":"ami-cf35f3a4",
    "instanceType":"t2.nano","provisioners":[]
  }],
  "bongo_":{
    "constructorName":"JStackTemplate",
    "instanceId":"bc16097c5934e4a0ee66aa5ea359858d"
  },
  "isDefault":false,
  "watchers":{},
  "title":"Default stack template3",
  "template":{
    "content":"{&quot;provider&quot;:{&quot;aws&quot;:{&quot;access_key&quot;:&quot;${var.aws_access_key}&quot;,&quot;secret_key&quot;:&quot;${var.aws_secret_key}&quot;}},&quot;resource&quot;:{&quot;aws_instance&quot;:{&quot;example_1&quot;:{&quot;instance_type&quot;:&quot;t2.nano&quot;,&quot;ami&quot;:&quot;&quot;,&quot;tags&quot;:{&quot;Name&quot;:&quot;${var.koding_user_username}-${var.koding_group_slug}&quot;},&quot;user_data&quot;:&quot;echo \\&quot;${var.custom_foo}\\&quot;&quot;}}}}",
    "details":{
      "lastUpdaterId":"57043a0bd37cef1a22a5c427"
    },
    "rawContent":"# Here is your stack preview\n# You can make advanced changes like modifying your VM,\n# installing packages, and running shell commands.\n\nprovider:\n  aws:\n    access_key: &#39;${var.aws_access_key}&#39;\n    secret_key: &#39;${var.aws_secret_key}&#39;\nresource:\n  aws_instance:\n    example_1:\n      instance_type: t2.nano\n      ami: &#39;&#39;\n      tags:\n        Name: &#39;${var.koding_user_username}-${var.koding_group_slug}&#39;\n      user_data: |-\n        echo &quot;${var.custom_foo}&quot;",
    "sum":"e254e25e7a0f0ca90af8dfd801e4a9d27009ac51"
  },
  "_id":"57044a868e15dd3674060106",
  "credentials":{
    "aws":["f1e165b7aa83885c935523c1e75f9403"],
    "custom":["9fa6487ff3ba89ded41c062590989750"]
  },
  "description":"##### Readme text for this stack template\n\nYou can write down a readme text for new users.\nThis text will be shown when they want to use this stack.\nYou can use markdown with the readme content.\n\n",
  "group":"kiskis"
}
