---
layout: "atlas"
page_title: "Atlas: atlas_artifact"
sidebar_current: "docs-atlas-resource-artifact"
description: |-
  Provides access to deployment artifacts managed by Atlas. This can
  be used to dynamically configure instantiation and provisioning
  of resources.
---

# atlas\_artifact

Provides access to deployment artifacts managed by Atlas. This can
be used to dynamically configure instantiation and provisioning
of resources.

## Example Usage

An artifact can be created that has metadata representing
an AMI in AWS. This AMI can be used to configure an instance. Any changes
to this artifact will trigger a change to that instance.

```
# Read the AMI
resource "atlas_artifact" "web" {
    name = "hashicorp/web"
    type = "amazon.ami"
    build = "latest"
    metadata {
        arch = "386"
    }
}

# Start our instance with the dynamic ami value
resource "aws_instance" "app" {
    ami = "${atlas_artifact.web.id}"
    ...
}
```

## Argument Reference

The following arguments are supported:

* `name` - (Required) Name of the artifact in Atlas. This is given
  in slug format like "organization/artifact".

* `type` - (Required) The type of artifact to query for.

* `build` - (Optional) The build number responsible for creating
  the version of the artifact to filter on. This can be "latest",
  to find a matching artifact in the latest build, "any" to find a
  matching artifact in any build, or a specific number to pin to that
  build. If `build` and `version` are unspecified, `version` will default
  to "latest". Cannot be specified with `version`.

* `version` - (Optional)  The version of the artifact to filter on. This can
  be "latest", to match against the latest version, "any" to find a matching artifact
  in any version, or a specific number to pin to that version. Defaults to
  "latest" if neither `build` or `version` is specified. Cannot be specified
  with `build`.

* `metadata_keys` - (Optional) If given, only an artifact containing
  the given keys will be returned. This is used to disambiguate when
  multiple potential artifacts match. An example is "aws" to filter
  on an AMI.

* `metadata` - (Optional) If given, only an artifact matching the
  metadata filters will be returned. This is used to disambiguate when
  multiple potential artifacts match. An example is "arch" = "386" to
  filter on architecture.


## Attributes Reference

The following attributes are exported:

* `id` - The ID of the artifact. This could be an AMI ID, GCE Image ID, etc.
* `file_url` - For artifacts that are binaries, this is a download path.
* `metadata_full` - Contains the full metadata of the artifact. The keys are sanitized
  to replace any characters that are invalid in a resource name with a hyphen.
  For example, the "region.us-east-1" key will become "region-us-east-1".
* `version_real` - The matching version of the artifact
* `slug` - The artifact slug in Atlas

