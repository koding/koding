---
layout: "docs"
page_title: "Module Sources"
sidebar_current: "docs-modules-sources"
description: Explains the use of the source parameter, which tells Terraform where modules can be found.
---

# Module Sources

As documented in the [Usage section](/docs/modules/usage.html), the only required parameter when using a module is `source`. The `source` parameter tells Terraform where the module can be found and what constraints to put on the module. Constraints can include a specific version or Git branch.

Terraform manages modules for you: it downloads them, organizes them on disk, checks for updates, etc. Terraform uses this `source` parameter to determine where it should retrieve and update modules from.

Terraform supports the following sources:

  * Local file paths

  * GitHub

  * Bitbucket

  * Generic Git, Mercurial repositories

  * HTTP URLs

  * S3 buckets

Each is documented further below.

## Local File Paths

The easiest source is the local file path. For maximum portability, this should be a relative file path into a subdirectory. This allows you to organize your Terraform configuration into modules within one repository, for example:

```hcl
module "consul" {
  source = "./consul"
}
```

Updates for file paths are automatic: when "downloading" the module using the [get command](/docs/commands/get.html), Terraform will create a symbolic link to the original directory. Therefore, any changes are automatically available.

## GitHub

Terraform will automatically recognize GitHub URLs and turn them into a link to the specific Git repository. The syntax is simple:

```hcl
module "consul" {
  source = "github.com/hashicorp/example"
}
```

Subdirectories within the repository can also be referenced:

```hcl
module "consul" {
  source = "github.com/hashicorp/example//subdir"
}
```

These will fetch the modules using HTTPS.  If you want to use SSH instead:

```hcl
module "consul" {
  source = "git@github.com:hashicorp/example.git//subdir"
}
```

**Note:** The double-slash, `//`, is important. It is what tells Terraform that that is the separator for a subdirectory, and not part of the repository itself.

GitHub source URLs require that Git is installed on your system and that you have access to the repository.

You can use the same parameters to GitHub repositories as you can generic Git repositories (such as tags or branches). See the documentation for generic Git repositories for more information.

### Private GitHub Repos

If you need Terraform to be able to fetch modules from private GitHub repos on a remote machine (like Terraform Enterprise or a CI server), you'll need to provide Terraform with credentials that can be used to authenticate as a user with read access to the private repo.

First, create a [machine user](https://developer.github.com/guides/managing-deploy-keys/#machine-users) on GitHub with read access to the private repo in question, then embed this user's credentials into the `source` parameter:

```hcl
module "private-infra" {
  source = "git::https://MACHINE-USER:MACHINE-PASS@github.com/org/privatemodules//modules/foo"
}
```

**Note:** Terraform does not yet support interpolations in the `source` field, so the machine username and password will have to be embedded directly into the `source` string. You can track [GH-1439](https://github.com/hashicorp/terraform/issues/1439) to learn when this limitation is addressed.

## Bitbucket

Terraform will automatically recognize public Bitbucket URLs and turn them into a link to the specific Git or Mercurial repository, for example:

```hcl
module "consul" {
  source = "bitbucket.org/hashicorp/consul"
}
```

Subdirectories within the repository can also be referenced:

```hcl
module "consul" {
  source = "bitbucket.org/hashicorp/consul//subdir"
}
```

**Note:** The double-slash, `//`, is important. It is what tells Terraform that this is the separator for a subdirectory, and not part of the repository itself.

Bitbucket URLs will require that Git or Mercurial is installed on your system, depending on the type of repository.

## Private Bitbucket Repos
Private bitbucket repositories must be specified similar to the Generic Git Respository section below.

```hcl
module "consul" {
  source = "git::https://bitbucket.org/foocompany/module_name.git
}
```

You can also specify branches and version withs the ?ref query

```hcl
module "consul" {
  source = "git::https://bitbucket.org/foocompany/module_name.git?hotfix
}
```

You will need to run a `terraform get -update=true` if you want to pull the latest versions. This can be handy when you are rapidly iterating on a module in development.

## Generic Git Repository

Generic Git repositories are also supported. The value of `source` in this case should be a complete Git-compatible URL. Using generic Git repositories requires that Git is installed on your system.

```hcl
module "consul" {
  source = "git://hashicorp.com/consul.git"
}
```

You can also use protocols such as HTTP or SSH to reference a module, but you'll have specify to Terraform that it is a Git module, by prefixing the URL with `git::` like so:

```hcl
module "consul" {
  source = "git::https://hashicorp.com/consul.git"
}

module "ami" {
  source = "git::ssh://git@github.com/owner/repo.git"
}
```

If you do not specify the type of `source` then Terraform will attempt to use the closest match, for example assuming `https://hashicorp.com/consul.git` is a HTTP URL.

The URLs for Git repositories support the following query parameters:

  * `ref` - The ref to checkout. This can be a branch, tag, commit, etc.

```hcl
module "consul" {
  source = "git::https://hashicorp.com/consul.git?ref=master"
}
```

Terraform will cache the module locally by default `terraform get` is run, so successive updates to master or a specified branch will not be factored into future plans. Run `terraform get -update=true` to get the latest version of the branch. This is handy in development, but potentially bothersome in production if you don't have control of the repository.

## Generic Mercurial Repository

Generic Mercurial repositories are supported. The value of `source` in this case should be a complete Mercurial-compatible URL. Using generic Mercurial repositories requires that Mercurial is installed on your system. You must tell Terraform that your `source` is a Mercurial repository by prefixing it with `hg::`.

```hcl
module "consul" {
  source = "hg::http://hashicorp.com/consul.hg"
}
```

URLs for Mercurial repositories support the following query parameters:

  * `rev` - The rev to checkout. This can be a branch, tag, commit, etc.

```hcl
module "consul" {
  source = "hg::http://hashicorp.com/consul.hg?rev=default"
}
```

## HTTP URLs

An HTTP or HTTPS URL can be used to redirect Terraform to get the module source from one of the other sources.  For HTTP URLs, Terraform will make a `GET` request to the given URL. An additional `GET` parameter, `terraform-get=1`, will be appended, allowing
you to optionally render the page differently when Terraform is requesting it.

Terraform then looks for the resulting module URL in the following order:

1. Terraform will look to see if the header `X-Terraform-Get` is present. The header should contain the source URL of the actual module.

2. Terraform will look for a `<meta>` tag with the name of `terraform-get`, for example:

```html
<meta name="terraform-get” content="github.com/hashicorp/example" />
```

### S3 Bucket

Terraform can also store modules in an S3 bucket. To access the bucket
you must have appropriate AWS credentials in your configuration or
available via shared credentials or environment variables.

There are a variety of S3 bucket addressing schemes, most are
[documented in the S3
configuration](http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html#access-bucket-intro).
Here are a couple of examples.

Using the `s3` protocol.

```hcl
module "consul" {
  source = "s3::https://s3-eu-west-1.amazonaws.com/consulbucket/consul.zip"
}
```

Or directly using the bucket's URL.

```hcl
module "consul" {
  source = "consulbucket.s3-eu-west-1.amazonaws.com/consul.zip"
}
```


## Unarchiving

Terraform will automatically unarchive files based on the extension of
the file being requested (over any protocol). It supports the following
archive formats:

* tar.gz and tgz
* tar.bz2 and tbz2
* zip
* gz
* bz2
