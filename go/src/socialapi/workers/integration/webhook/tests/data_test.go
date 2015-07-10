package tests

var githubPushEventData = `{
  "ref": "refs/heads/master",
  "before": "7208d1cff86aea3e5e4de5e5e622cb2ecbdd3b05",
  "after": "24970ee50ffa4395d14c2a1ceea798e76cbe61fb",
  "created": false,
  "deleted": false,
  "forced": true,
  "base_ref": null,
  "compare": "https://github.com/canthefason/testing/compare/7208d1cff86a...24970ee50ffa",
  "commits": [
    {
      "id": "24970ee50ffa4395d14c2a1ceea798e76cbe61fb",
      "distinct": true,
      "message": "initial commit",
      "timestamp": "2015-06-23T15:31:22-07:00",
      "url": "https://github.com/canthefason/testing/commit/24970ee50ffa4395d14c2a1ceea798e76cbe61fb",
      "author": {
        "name": "Can Yucel",
        "email": "can@koding.com",
        "username": "canthefason"
      },
      "committer": {
        "name": "Can Yucel",
        "email": "can@koding.com",
        "username": "canthefason"
      },
      "added": [
        "main.go"
      ],
      "removed": [

      ],
      "modified": [

      ]
    }
  ],
  "head_commit": {
    "id": "24970ee50ffa4395d14c2a1ceea798e76cbe61fb",
    "distinct": true,
    "message": "initial commit",
    "timestamp": "2015-06-23T15:31:22-07:00",
    "url": "https://github.com/canthefason/testing/commit/24970ee50ffa4395d14c2a1ceea798e76cbe61fb",
    "author": {
      "name": "Can Yucel",
      "email": "can@koding.com",
      "username": "canthefason"
    },
    "committer": {
      "name": "Can Yucel",
      "email": "can@koding.com",
      "username": "canthefason"
    },
    "added": [
      "main.go"
    ],
    "removed": [

    ],
    "modified": [

    ]
  },
  "repository": {
    "id": 37752870,
    "name": "testing",
    "full_name": "canthefason/testing",
    "owner": {
      "name": "canthefason",
      "email": "can.yucel@gmail.com"
    },
    "private": true,
    "html_url": "https://github.com/canthefason/testing",
    "description": "",
    "fork": false,
    "url": "https://github.com/canthefason/testing",
    "forks_url": "https://api.github.com/repos/canthefason/testing/forks",
    "keys_url": "https://api.github.com/repos/canthefason/testing/keys{/key_id}",
    "collaborators_url": "https://api.github.com/repos/canthefason/testing/collaborators{/collaborator}",
    "teams_url": "https://api.github.com/repos/canthefason/testing/teams",
    "hooks_url": "https://api.github.com/repos/canthefason/testing/hooks",
    "issue_events_url": "https://api.github.com/repos/canthefason/testing/issues/events{/number}",
    "events_url": "https://api.github.com/repos/canthefason/testing/events",
    "assignees_url": "https://api.github.com/repos/canthefason/testing/assignees{/user}",
    "branches_url": "https://api.github.com/repos/canthefason/testing/branches{/branch}",
    "tags_url": "https://api.github.com/repos/canthefason/testing/tags",
    "blobs_url": "https://api.github.com/repos/canthefason/testing/git/blobs{/sha}",
    "git_tags_url": "https://api.github.com/repos/canthefason/testing/git/tags{/sha}",
    "git_refs_url": "https://api.github.com/repos/canthefason/testing/git/refs{/sha}",
    "trees_url": "https://api.github.com/repos/canthefason/testing/git/trees{/sha}",
    "statuses_url": "https://api.github.com/repos/canthefason/testing/statuses/{sha}",
    "languages_url": "https://api.github.com/repos/canthefason/testing/languages",
    "stargazers_url": "https://api.github.com/repos/canthefason/testing/stargazers",
    "contributors_url": "https://api.github.com/repos/canthefason/testing/contributors",
    "subscribers_url": "https://api.github.com/repos/canthefason/testing/subscribers",
    "subscription_url": "https://api.github.com/repos/canthefason/testing/subscription",
    "commits_url": "https://api.github.com/repos/canthefason/testing/commits{/sha}",
    "git_commits_url": "https://api.github.com/repos/canthefason/testing/git/commits{/sha}",
    "comments_url": "https://api.github.com/repos/canthefason/testing/comments{/number}",
    "issue_comment_url": "https://api.github.com/repos/canthefason/testing/issues/comments{/number}",
    "contents_url": "https://api.github.com/repos/canthefason/testing/contents/{+path}",
    "compare_url": "https://api.github.com/repos/canthefason/testing/compare/{base}...{head}",
    "merges_url": "https://api.github.com/repos/canthefason/testing/merges",
    "archive_url": "https://api.github.com/repos/canthefason/testing/{archive_format}{/ref}",
    "downloads_url": "https://api.github.com/repos/canthefason/testing/downloads",
    "issues_url": "https://api.github.com/repos/canthefason/testing/issues{/number}",
    "pulls_url": "https://api.github.com/repos/canthefason/testing/pulls{/number}",
    "milestones_url": "https://api.github.com/repos/canthefason/testing/milestones{/number}",
    "notifications_url": "https://api.github.com/repos/canthefason/testing/notifications{?since,all,participating}",
    "labels_url": "https://api.github.com/repos/canthefason/testing/labels{/name}",
    "releases_url": "https://api.github.com/repos/canthefason/testing/releases{/id}",
    "created_at": 1434761976,
    "updated_at": "2015-06-20T01:38:27Z",
    "pushed_at": 1435098697,
    "git_url": "git://github.com/canthefason/testing.git",
    "ssh_url": "git@github.com:canthefason/testing.git",
    "clone_url": "https://github.com/canthefason/testing.git",
    "svn_url": "https://github.com/canthefason/testing",
    "homepage": null,
    "size": 0,
    "stargazers_count": 0,
    "watchers_count": 0,
    "language": "Go",
    "has_issues": true,
    "has_downloads": true,
    "has_wiki": true,
    "has_pages": false,
    "forks_count": 0,
    "mirror_url": null,
    "open_issues_count": 0,
    "forks": 0,
    "open_issues": 0,
    "watchers": 0,
    "default_branch": "master",
    "stargazers": 0,
    "master_branch": "master"
  },
  "pusher": {
    "name": "canthefason",
    "email": "can.yucel@gmail.com"
  },
  "sender": {
    "login": "canthefason",
    "id": 73976,
    "avatar_url": "https://avatars.githubusercontent.com/u/73976?v=3",
    "gravatar_id": "",
    "url": "https://api.github.com/users/canthefason",
    "html_url": "https://github.com/canthefason",
    "followers_url": "https://api.github.com/users/canthefason/followers",
    "following_url": "https://api.github.com/users/canthefason/following{/other_user}",
    "gists_url": "https://api.github.com/users/canthefason/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/canthefason/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/canthefason/subscriptions",
    "organizations_url": "https://api.github.com/users/canthefason/orgs",
    "repos_url": "https://api.github.com/users/canthefason/repos",
    "events_url": "https://api.github.com/users/canthefason/events{/privacy}",
    "received_events_url": "https://api.github.com/users/canthefason/received_events",
    "type": "User",
    "site_admin": false
  }
}`
