## 0.6.13 (Unreleased)

BACKWARDS INCOMPATIBILITIES / NOTES:

  * provider/aws: `aws_s3_bucket_object` field `etag` is now trimming off quotes (returns raw MD5 hash) [GH-5305]

IMPROVEMENTS:

  * provider/aws: Enable updates & versioning for `aws_s3_bucket_object` [GH-5305]
  * provider/vsphere: Add support for disk init types [GH-4284]

## 0.6.12 (February 24, 2016)

BACKWARDS INCOMPATIBILITIES / NOTES:

  * The `publicly_accessible` attribute on `aws_redshift_cluster` resources now defaults to true

FEATURES:

  * **New command:** `validate` to perform syntax validation [GH-3783]
  * **New provider:** `datadog` [GH-5251]
  * **New interpolation function:** `md5` [GH-5267]
  * **New interpolation function:** `signum` [GH-4854]
  * **New resource:** `aws_cloudwatch_event_rule` [GH-4986]
  * **New resource:** `aws_cloudwatch_event_target` [GH-4986]
  * **New resource:** `aws_lambda_permission` [GH-4826]
  * **New resource:** `azurerm_dns_a_record` [GH-5013]
  * **New resource:** `azurerm_dns_aaaa_record` [GH-5013]
  * **New resource:** `azurerm_dns_cname_record` [GH-5013]
  * **New resource:** `azurerm_dns_mx_record` [GH-5041]
  * **New resource:** `azurerm_dns_ns_record` [GH-5041]
  * **New resource:** `azurerm_dns_srv_record` [GH-5041]
  * **New resource:** `azurerm_dns_txt_record` [GH-5041]
  * **New resource:** `azurerm_dns_zone` [GH-4979]
  * **New resource:** `azurerm_search_service` [GH-5203]
  * **New resource:** `azurerm_sql_database` [GH-5003]
  * **New resource:** `azurerm_sql_firewall_rule` [GH-5057]
  * **New resource:** `azurerm_sql_server` [GH-4991]
  * **New resource:** `google_compute_subnetwork` [GH-5130]

IMPROVEMENTS:

  * core: Backend names are now down cased during `init` in the same manner as `remote config` [GH-5012]
  * core: Upgrade resource name validation warning to an error as planned [GH-5272]
  * core: output "diffs didn't match" error details [GH-5276]
  * provider/aws: Add `is_multi_region_trail` option to CloudTrail [GH-4939]
  * provider/aws: Add support for HTTP(S) endpoints that auto confirm SNS subscription [GH-4711]
  * provider/aws: Add support for Tags to CloudTrail [GH-5135]
  * provider/aws: Add support for Tags to ElasticSearch [GH-4973]
  * provider/aws: Add support for deployment configuration to `aws_ecs_service` [GH-5220]
  * provider/aws: Add support for log validation + KMS encryption to `aws_cloudtrail` [GH-5051]
  * provider/aws: Allow name-prefix and auto-generated names for IAM Server Cert [GH-5178]
  * provider/aws: Expose additional VPN Connection attributes [GH-5032]
  * provider/aws: Return an error if no matching route is found for an AWS Route [GH-5155]
  * provider/aws: Support custom endpoints for AWS EC2 ELB and IAM [GH-5114]
  * provider/aws: The `cluster_type` on `aws_redshift_cluster` resources is now computed [GH-5238]
  * provider/aws: `aws_lambda_function` resources now support VPC configuration [GH-5149]
  * provider/aws: Add support for Enhanced Monitoring to RDS Instances [GH-4945]
  * provider/aws: Improve vpc cidr_block err message [GH-5255]
  * provider/aws: Implement Retention Period for `aws_kinesis_stream` [GH-5223]
  * provider/aws: Enable `stream_arm` output for DynamoDB Table when streams are enabled [GH-5271]
  * provider/digitalocean: `digitalocean_record` resources now export a computed `fqdn` attribute [GH-5071]
  * provider/google: Add assigned IP Address to CloudSQL Instance `google_sql_database_instance` [GH-5245]
  * provider/openstack: Add support for Distributed Routers [GH-4878]
  * provider/openstack: Add support for optional cacert_file parameter [GH-5106]

BUG FIXES:

  * core: Fix bug detecting deeply nested module orphans [GH-5022]
  * core: Fix bug where `ignore_changes` could produce "diffs didn't match during apply" errors [GH-4965]
  * core: Fix race condition when handling tainted resource destroys [GH-5026]
  * core: Improve handling of Provisioners in the graph, fixing "Provisioner already initialized" errors [GH-4877]
  * core: Skip `create_before_destroy` processing during a `terraform destroy`, solving several issues preventing `destroy`
          from working properly with CBD resources [GH-5096]
  * core: Error instead of panic on self var in wrong scope [GH-5273]
  * provider/aws: Fix Copy of Tags to DB Instance when created from Snapshot [GH-5197]
  * provider/aws: Fix DynamoDB Table Refresh to ensure deleted tables are removed from state [GH-4943]
  * provider/aws: Fix ElasticSearch `domain_name` validation [GH-4973]
  * provider/aws: Fix issue applying security group changes in EC2 Classic RDS for aws_db_instance [GH-4969]
  * provider/aws: Fix reading auto scaling group availability zones [GH-5044]
  * provider/aws: Fix reading auto scaling group load balancers [GH-5045]
  * provider/aws: Fix `aws_redshift_cluster` to allow `publicly_accessible` to be false [GH-5262]
  * provider/aws: Wait longer for internet gateways to detach [GH-5120]
  * provider/aws: Fix issue reading auto scaling group termination policies [GH-5101]
  * provider/cloudflare: `ttl` no longer shows a change on each plan on `cloudflare_record` resources [GH-5042]
  * provider/docker: Fix the default docker_host value [GH-5088]
  * provider/google: Fix backend service max_utilization attribute [GH-5075]
  * provider/google: Fix reading of `google_compute_vpn_gateway` without an explicit [GH-5125]
  * provider/google: Fix crash when setting `ack_deadline_seconds` on `google_pubsub_subscription` [GH-5110]
  * provider/openstack: Fix crash when `access_network` was not defined in instances [GH-4966]
  * provider/powerdns: Fix refresh of `powerdns_record` no longer fails if the record name contains a `-` [GH-5228] 
  * provider/vcd: Wait for DHCP assignment when creating `vcd_vapp` resources with no static IP assignment [GH-5195]

## 0.6.11 (February 1, 2016)

BACKWARDS INCOMPATIBILITIES / NOTES:

  * The `max_size`, `min_size` and `desired_capacity` attributes on `aws_autoscaling_schedule` resources now default to 0

FEATURES:

  * **New provider: `powerdns` - PowerDNS REST API** [GH-4885]
  * **New builtin function:** `trimspace` for trimming whitespaces [GH-4910]
  * **New builtin function:** `base64sha256` for base64 encoding raw sha256 sum of a given string [GH-4899]
  * **New resource:** `openstack_lb_member_v1` [GH-4359]

IMPROVEMENTS:

  * provider/template: Remove unnecessary mime-type validation from `template_cloudinit_config` resources [GH-4873]
  * provider/template: Correct spelling of "Boundary" in the part separator of rendered `template_cloudinit_config` resources [GH-4873]
  * provider/aws: Provide a better message if no AWS creds are found [GH-4869]
  * provider/openstack: Ability to specify per-network Floating IPs [GH-4812] 
 
BUG FIXES:

  * provider/aws: `aws_autoscale_schedule` 0 values [GH-4693]
  * provider/aws: Fix regression with VPCs and ClassicLink for regions that do not support it [GH-4879]
  * provider/aws: Change VPC ClassicLink to be computed [GH-4933]
  * provider/aws: Fix SNS Topic Refresh to ensure deleted topics are removed from state [GH-4891]
  * provider/aws: Refactor Route53 record to fix regression in deleting records created in previous versions of Terraform [GH-4892]
  * provider/azurerm: Fix panic if no creds supplied [GH-4902]
  * provider/openstack: Changing the port resource to mark the ip_address as optional [GH-4850]
  * provider/docker: Catch potential custom network errors in docker [GH-4918]
  


## 0.6.10 (January 27, 2016)

BACKWARDS INCOMPATIBILITIES / NOTES:

  * The `-module-depth` flag available on `plan`, `apply`, `show`, and `graph` now defaults to `-1`, causing
    resources within modules to be expanded in command output. This is only a cosmetic change; it does not affect
    any behavior.
  * This release includes a bugfix for `$${}` interpolation escaping. These strings are now properly converted to `${}`
    during interpolation. This may cause diffs on existing configurations in certain cases.
  * Users of `consul_keys` should note that the `value` sub-attribute of `key` will no longer be updated with the remote value of the key. It should be only used to _set_ a key in Consul K/V. To reference key values, use the `var` attribute.
  * The 0.6.9 release contained a regression in `aws_autoscaling_group` capacity waiting behavior for configs where `min_elb_capacity != desired_capacity` or `min_size != desired_capacity`. This release remedies that regression by un-deprecating `min_elb_capacity` and restoring the prior behavior.
  * Users of `aws_security_group` may notice new diffs in initial plans with 0.6.10 due to a bugfix that fixes drift detection on nested security group rules. These new diffs should reflect the actual state of the resources, which Terraform previously was unable to see.


FEATURES:

  * **New resource: `aws_lambda_alias`** [GH-4664]
  * **New resource: `aws_redshift_cluster`** [GH-3862]
  * **New resource: `aws_redshift_parameter_group`** [GH-3862]
  * **New resource: `aws_redshift_security_group`** [GH-3862]
  * **New resource: `aws_redshift_subnet_group`** [GH-3862]
  * **New resource: `azurerm_cdn_endpoint`** [GH-4759]
  * **New resource: `azurerm_cdn_profile`** [GH-4740]
  * **New resource: `azurerm_network_interface`** [GH-4598]
  * **New resource: `azurerm_network_security_rule`** [GH-4586]
  * **New resource: `azurerm_route_table`** [GH-4602]
  * **New resource: `azurerm_route`** [GH-4604]
  * **New resource: `azurerm_storage_account`** [GH-4698]
  * **New resource: `azurerm_storage_blob`** [GH-4862]
  * **New resource: `azurerm_storage_container`** [GH-4862]
  * **New resource: `azurerm_storage_queue`** [GH-4862]
  * **New resource: `azurerm_subnet`** [GH-4595]
  * **New resource: `docker_network`** [GH-4483]
  * **New resource: `docker_volume`** [GH-4483]
  * **New resource: `google_sql_user`** [GH-4669]

IMPROVEMENTS:

  * core: Add `sha256()` interpolation function [GH-4704]
  * core: Validate lifecycle keys to show helpful error messages whe they are mistypes [GH-4745]
  * core: Default `module-depth` parameter to `-1`, which expands resources within modules in command output [GH-4763]
  * core: Variable types may now be specified explicitly using the `type` argument [GH-4795]
  * provider/aws: Add new parameters `az_mode` and `availability_zone(s)` in ElastiCache [GH-4631]
  * provider/aws: Allow ap-northeast-2 (Seoul) as valid region [GH-4637]
  * provider/aws: Limit SNS Topic Subscription protocols [GH-4639]
  * provider/aws: Add support for configuring logging on `aws_s3_bucket` resources [GH-4482]
  * provider/aws: Add AWS Classiclink for AWS VPC resource [GH-3994]
  * provider/aws: Supporting New AWS Route53 HealthCheck additions [GH-4564]
  * provider/aws: Store instance state [GH-3261]
  * provider/aws: Add support for updating ELB availability zones and subnets [GH-4597]
  * provider/aws: Enable specifying aws s3 redirect protocol [GH-4098]
  * provider/aws: Added support for `encrypted` on `ebs_block_devices` in Launch Configurations [GH-4481]
  * provider/aws: Retry Listener Creation for ELBs [GH-4825]
  * provider/aws: Add support for creating Managed Microsoft Active Directory 
    and Directory Connectors [GH-4388]
  * provider/aws: Mark some `aws_db_instance` fields as optional [GH-3138]
  * provider/digitalocean: Add support for reassigning `digitalocean_floating_ip` resources [GH-4476]
  * provider/dme: Add support for Global Traffic Director locations on `dme_record` resources [GH-4305]
  * provider/docker: Add support for adding host entries on `docker_container` resources [GH-3463]
  * provider/docker: Add support for mounting named volumes on `docker_container` resources [GH-4480]
  * provider/google: Add content field to bucket object [GH-3893]
  * provider/google: Add support for  `named_port` blocks on `google_compute_instance_group_manager` resources [GH-4605]
  * provider/openstack: Add "personality" support to instance resource [GH-4623]
  * provider/packet: Handle external state changes for Packet resources gracefully [GH-4676]
  * provider/tls: `tls_private_key` now exports attributes with public key in both PEM and OpenSSH format [GH-4606]
  * provider/vdc: Add `allow_unverified_ssl` for connections to vCloud API [GH-4811]
  * state/remote: Allow KMS Key Encryption to be used with S3 backend [GH-2903]

BUG FIXES:

  * core: Fix handling of literals with escaped interpolations `$${var}` [GH-4747]
  * core: Fix diff mismatch when RequiresNew field and list both change [GH-4749]
  * core: Respect module target path argument on `terraform init` [GH-4753]
  * core: Write planfile even on empty plans [GH-4766]
  * core: Add validation error when output is missing value field [GH-4762]
  * core: Fix improper handling of orphan resources when targeting [GH-4574]
  * core: Properly handle references to computed set attributes [GH-4840]
  * config: Detect a specific JSON edge case and show a helpful workaround [GH-4746]
  * provider/openstack: Ensure valid Security Group Rule attribute combination [GH-4466]
  * provider/openstack: Don't put fixed_ip in port creation request if not defined [GH-4617]
  * provider/google: Clarify SQL Database Instance recent name restriction [GH-4577]
  * provider/google: Split Instance network interface into two fields [GH-4265]
  * provider/aws: Error with empty list item on security group [GH-4140]
  * provider/aws: Fix issue with detecting drift in AWS Security Groups rules [GH-4779]
  * provider/aws: Trap Instance error from mismatched SG IDs and Names [GH-4240]
  * provider/aws: EBS optimised to force new resource in AWS Instance [GH-4627]
  * provider/aws: Wait for NACL rule to be visible [GH-4734]
  * provider/aws: `default_result` on `aws_autoscaling_lifecycle_hook` resources is now computed [GH-4695]
  * provider/aws: fix ASG capacity waiting regression by un-deprecating `min_elb_capacity` [GH-4864]
  * provider/consul: fix several bugs surrounding update behavior [GH-4787]
  * provider/mailgun: Handle the fact that the domain destroy API is eventually consistent [GH-4777]
  * provider/template: Fix race causing sporadic crashes in template_file with count > 1 [GH-4694]
  * provider/template: Add support for updating `template_cloudinit_config` resources [GH-4757]
  * provisioner/chef: Add ENV['no_proxy'] to chef provisioner if no_proxy is detected [GH-4661]

## 0.6.9 (January 8, 2016)

FEATURES:

  * **New provider: `vcd` - VMware vCloud Director** [GH-3785]
  * **New provider: `postgresql` - Create PostgreSQL databases and roles** [GH-3653]
  * **New provider: `chef` - Create chef environments, roles, etc** [GH-3084]
  * **New provider: `azurerm` - Preliminary support for Azure Resource Manager** [GH-4226]
  * **New provider: `mysql` - Create MySQL databases** [GH-3122]
  * **New resource: `aws_autoscaling_schedule`** [GH-4256]
  * **New resource: `aws_nat_gateway`** [GH-4381]
  * **New resource: `aws_network_acl_rule`** [GH-4286]
  * **New resources: `aws_ecr_repository` and `aws_ecr_repository_policy`** [GH-4415]
  * **New resource: `google_pubsub_topic`** [GH-3671]
  * **New resource: `google_pubsub_subscription`** [GH-3671]
  * **New resource: `template_cloudinit_config`** [GH-4095]
  * **New resource: `tls_locally_signed_cert`** [GH-3930]
  * **New remote state backend: `artifactory`** [GH-3684]

IMPROVEMENTS:

  * core: Change set internals for performance improvements [GH-3992]
  * core: Support HTTP basic auth in consul remote state [GH-4166]
  * core: Improve error message on resource arity mismatch [GH-4244]
  * core: Add support for unary operators + and - to the interpolation syntax [GH-3621]
  * core: Add SSH agent support for Windows [GH-4323]
  * core: Add `sha1()` interpolation function [GH-4450]
  * provider/aws: Add `placement_group` as an option for `aws_autoscaling_group` [GH-3704]
  * provider/aws: Add support for DynamoDB Table StreamSpecifications [GH-4208]
  * provider/aws: Add `name_prefix` to Security Groups [GH-4167]
  * provider/aws: Add support for removing nodes to `aws_elasticache_cluster` [GH-3809]
  * provider/aws: Add support for `skip_final_snapshot` to `aws_db_instance` [GH-3853]
  * provider/aws: Adding support for Tags to DB SecurityGroup [GH-4260]
  * provider/aws: Adding Tag support for DB Param Groups [GH-4259]
  * provider/aws: Fix issue with updated route ids for VPC Endpoints [GH-4264]
  * provider/aws: Added measure_latency option to Route 53 Health Check resource [GH-3688]
  * provider/aws: Validate IOPs for EBS Volumes [GH-4146]
  * provider/aws: DB Subnet group arn output [GH-4261]
  * provider/aws: Get full Kinesis streams view with pagination [GH-4368]
  * provider/aws: Allow changing private IPs for ENIs [GH-4307]
  * provider/aws: Retry MalformedPolicy errors due to newly created principals in S3 Buckets [GH-4315]
  * provider/aws: Validate `name` on `db_subnet_group` against AWS requirements [GH-4340]
  * provider/aws: wait for ASG capacity on update [GH-3947]
  * provider/aws: Add validation for ECR repository name [GH-4431]
  * provider/cloudstack: performance improvements [GH-4150]
  * provider/docker: Add support for setting the entry point on `docker_container` resources [GH-3761]
  * provider/docker: Add support for setting the restart policy on `docker_container` resources [GH-3761]
  * provider/docker: Add support for setting memory, swap and CPU shares on `docker_container` resources [GH-3761]
  * provider/docker: Add support for setting labels on `docker_container` resources [GH-3761]
  * provider/docker: Add support for setting log driver and options on `docker_container` resources [GH-3761]
  * provider/docker: Add support for settings network mode on `docker_container` resources [GH-4475]
  * provider/heroku: Improve handling of Applications within an Organization [GH-4495]
  * provider/vsphere: Add support for custom vm params on `vsphere_virtual_machine` [GH-3867]
  * provider/vsphere: Rename vcenter_server config parameter to something clearer [GH-3718]
  * provider/vsphere: Make allow_unverified_ssl a configuable on the provider [GH-3933]
  * provider/vsphere: Add folder handling for folder-qualified vm names [GH-3939]
  * provider/vsphere: Change ip_address parameter for ipv6 support [GH-4035]
  * provider/openstack: Increase instance timeout from 10 to 30 minutes [GH-4223]
  * provider/google: Add `restart_policy` attribute to `google_managed_instance_group` [GH-3892]

BUG FIXES:

  * core: skip provider input for deprecated fields [GH-4193]
  * core: Fix issue which could cause fields that become empty to retain old values in the state [GH-3257]
  * provider/docker: Fix an issue running with Docker Swarm by looking up containers by ID instead of name [GH-4148]
  * provider/openstack: Better handling of load balancing resource state changes [GH-3926]
  * provider/aws: Treat `INACTIVE` ECS cluster as deleted [GH-4364]
  * provider/aws: Skip `source_security_group_id` determination logic for Classic ELBs [GH-4075]
  * provider/aws: Fix issue destroy Route 53 zone/record if it no longer exists [GH-4198]
  * provider/aws: Fix issue force destroying a versioned S3 bucket [GH-4168]
  * provider/aws: Update DB Replica to honor storage type [GH-4155]
  * provider/aws: Fix issue creating AWS RDS replicas across regions [GH-4215]
  * provider/aws: Fix issue with Route53 and zero weighted records [GH-4427]
  * provider/aws: Fix issue with iam_profile in aws_instance when a path is specified [GH-3663]
  * provider/aws: Refactor AWS Authentication chain to fix issue with authentication and IAM [GH-4254]
  * provider/aws: Fix issue with finding S3 Hosted Zone ID for eu-central-1 region [GH-4236]
  * provider/aws: Fix missing AMI issue with Launch Configurations [GH-4242]
  * provider/aws: Opsworks stack SSH key is write-only [GH-4241]
  * provider/aws: Update VPC Endpoint to correctly set route table ids [GH-4392]
  * provider/aws: Fix issue with ElasticSearch Domain `access_policies` always appear changed [GH-4245]
  * provider/aws: Fix issue with nil parameter group value causing panic in `aws_db_parameter_group` [GH-4318]
  * provider/aws: Fix issue with Elastic IPs not recognizing when they have been unassigned manually [GH-4387]
  * provider/aws: Use body or URL for all CloudFormation stack updates [GH-4370]
  * provider/aws: Fix template_url/template_body conflict [GH-4540]
  * provider/aws: Fix bug w/ changing ECS svc/ELB association [GH-4366]
  * provider/aws: Fix RDS unexpected state config [GH-4490]
  * provider/digitalocean: Fix issue where a floating IP attached to a missing droplet causes a panic [GH-4214]
  * provider/google: Fix project metadata sshKeys from showing up and causing unnecessary diffs [GH-4512]
  * provider/heroku: Retry drain create until log channel is assigned [GH-4823]
  * provider/openstack: Handle volumes in "deleting" state [GH-4204]
  * provider/rundeck: Tolerate Rundeck server not returning project name when reading a job [GH-4301]
  * provider/vsphere: Create and attach additional disks before bootup [GH-4196]
  * provider/openstack: Convert block_device from a Set to a List [GH-4288]
  * provider/google: Terraform identifies deleted resources and handles them appropriately on Read [GH-3913]

## 0.6.8 (December 2, 2015)

FEATURES:

  * **New provider: `statuscake`** [GH-3340]
  * **New resource: `digitalocean_floating_ip`** [GH-3748]
  * **New resource: `aws_lambda_event_source_mapping`** [GH-4093]

IMPROVEMENTS:

  * provider/cloudstack: Reduce the number of network calls required for common operations [GH-4051]
  * provider/aws: Make `publically_accessible` on an `aws_db_instance` update existing instances instead of forcing new ones [GH-3895]
  * provider/aws: Allow `block_duration_minutes` to be set for spot instance requests [GH-4071]
  * provider/aws: Make setting `acl` on S3 buckets update existing buckets instead of forcing new ones [GH-4080]
  * provider/aws: Make updates to `assume_role_policy` modify existing IAM roles instead of forcing new ones [GH-4107]

BUG FIXES:

  * core: Fix a bug which prevented HEREDOC syntax being used in lists [GH-4078]
  * core: Fix a bug which prevented HEREDOC syntax where the anchor ends in a number [GH-4128]
  * core: Fix a bug which prevented HEREDOC syntax being used with Windows line endings [GH-4069]
  * provider/aws: Fix a bug which could result in a panic when reading EC2 metadata [GH-4024]
  * provider/aws: Fix issue recreating security group rule if it has been destroyed [GH-4050]
  * provider/aws: Fix issue with some attributes in Spot Instance Requests returning as nil [GH-4132]
  * provider/aws: Fix issue where SPF records in Route 53 could show differences with no modification to the configuration [GH-4108]
  * provisioner/chef: Fix issue with path separators breaking the Chef provisioner on Windows [GH-4041]

## 0.6.7 (November 23, 2015)

FEATURES:

  * **New provider: `tls`** - A utility provider for generating TLS keys/self-signed certificates for development and testing [GH-2778]
  * **New provider: `dyn`** - Manage DNS records on Dyn
  * **New resource: `aws_cloudformation_stack`** [GH-2636]
  * **New resource: `aws_cloudtrail`** [GH-3094], [GH-4010]
  * **New resource: `aws_route`** [GH-3548]
  * **New resource: `aws_codecommit_repository`** [GH-3274]
  * **New resource: `aws_kinesis_firehose_delivery_stream`** [GH-3833]
  * **New resource: `google_sql_database` and `google_sql_database_instance`** [GH-3617]
  * **New resource: `google_compute_global_address`** [GH-3701]
  * **New resource: `google_compute_https_health_check`** [GH-3883]
  * **New resource: `google_compute_ssl_certificate`** [GH-3723]
  * **New resource: `google_compute_url_map`** [GH-3722]
  * **New resource: `google_compute_target_http_proxy`** [GH-3727]
  * **New resource: `google_compute_target_https_proxy`** [GH-3728]
  * **New resource: `google_compute_global_forwarding_rule`** [GH-3702]
  * **New resource: `openstack_networking_port_v2`** [GH-3731]
  * New interpolation function: `coalesce` [GH-3814]

IMPROVEMENTS:

  * core: Improve message to list only resources which will be destroyed when using `--target` [GH-3859]
  * connection/ssh: Accept `private_key` contents instead of paths [GH-3846]
  * provider/google: `preemptible` option for instance_template [GH-3667]
  * provider/google: Accurate Terraform Version [GH-3554]
  * provider/google: Simplified auth (DefaultClient support) [GH-3553]
  * provider/google: `automatic_restart`, `preemptible`, `on_host_maintenance` options [GH-3643]
  * provider/google: Read credentials as contents instead of path [GH-3901]
  * null_resource: Enhance and document [GH-3244, GH-3659]
  * provider/aws: Add CORS settings to S3 bucket [GH-3387]
  * provider/aws: Add notification topic ARN for ElastiCache clusters [GH-3674]
  * provider/aws: Add `kinesis_endpoint` for configuring Kinesis [GH-3255]
  * provider/aws: Add a computed ARN for S3 Buckets [GH-3685]
  * provider/aws: Add S3 support for Lambda Function resource [GH-3794]
  * provider/aws: Add `name_prefix` option to launch configurations [GH-3802]
  * provider/aws: Add support for group name and path changes with IAM group update function [GH-3237]
  * provider/aws: Provide `source_security_group_id` for ELBs inside a VPC [GH-3780]
  * provider/aws: Add snapshot window and retention limits for ElastiCache (Redis) [GH-3707]
  * provider/aws: Add username updates for `aws_iam_user` [GH-3227]
  * provider/aws: Add AutoMinorVersionUpgrade to RDS Instances [GH-3677]
  * provider/aws: Add `access_logs` to ELB resource [GH-3756]
  * provider/aws: Add a retry function to rescue an error in creating Autoscaling Lifecycle Hooks [GH-3694]
  * provider/aws: `engine_version` is now optional for DB Instance [GH-3744]
  * provider/aws: Add configuration to enable copying RDS tags to final snapshot [GH-3529]
  * provider/aws: RDS Cluster additions (`backup_retention_period`, `preferred_backup_window`, `preferred_maintenance_window`) [GH-3757]
  * provider/aws: Document and validate ELB `ssl_certificate_id` and protocol requirements [GH-3887]
  * provider/azure: Read `publish_settings` as contents instead of path [GH-3899]
  * provider/openstack: Use IPv4 as the default IP version for subnets [GH-3091]
  * provider/aws: Apply security group after restoring `db_instance` from snapshot [GH-3513]
  * provider/aws: Make the AutoScalingGroup `name` optional [GH-3710]
  * provider/openstack: Add "delete on termination" boot-from-volume option [GH-3232]
  * provider/digitalocean: Make `user_data` force a new droplet [GH-3740]
  * provider/vsphere: Do not add network interfaces by default [GH-3652]
  * provider/openstack: Configure Fixed IPs through ports [GH-3772]
  * provider/openstack: Specify a port ID on a Router Interface [GH-3903]
  * provider/openstack: Make LBaaS Virtual IP computed [GH-3927]

BUG FIXES:

  * `terraform remote config`: update `--help` output [GH-3632]
  * core: Modules on Git branches now update properly [GH-1568]
  * core: Fix issue preventing input prompts for unset variables during plan [GH-3843]
  * core: Fix issue preventing input prompts for unset variables during refresh [GH-4017]
  * core: Orphan resources can now be targets [GH-3912]
  * helper/schema: Skip StateFunc when value is nil [GH-4002]
  * provider/google: Timeout when deleting large `instance_group_manager` [GH-3591]
  * provider/aws: Fix issue with order of Termination Policies in AutoScaling Groups.
      This will introduce plans on upgrade to this version, in order to correct the ordering [GH-2890]
  * provider/aws: Allow cluster name, not only ARN for `aws_ecs_service` [GH-3668]
  * provider/aws: Fix a bug where a non-lower-cased `maintenance_window` can cause unnecessary planned changes [GH-4020]
  * provider/aws: Only set `weight` on an `aws_route53_record` if it has been set in configuration [GH-3900]
  * provider/aws: Ignore association not existing on route table destroy [GH-3615]
  * provider/aws: Fix policy encoding issue with SNS Topics [GH-3700]
  * provider/aws: Correctly export ARN in `aws_iam_saml_provider` [GH-3827]
  * provider/aws: Fix issue deleting users who are attached to a group [GH-4005]
  * provider/aws: Fix crash in Route53 Record if Zone not found [GH-3945]
  * provider/aws: Retry deleting IAM Server Cert on dependency violation [GH-3898]
  * provider/aws: Update Spot Instance request to provide connection information [GH-3940]
  * provider/aws: Fix typo in error checking for IAM Policy Attachments [GH-3970]
  * provider/aws: Fix issue with LB Cookie Stickiness and empty expiration period [GH-3908]
  * provider/aws: Tolerate ElastiCache clusters being deleted outside Terraform [GH-3767]
  * provider/aws: Downcase Route 53 record names in state file to match API output [GH-3574]
  * provider/aws: Fix issue that could occur if no ECS Cluster was found for a given name [GH-3829]
  * provider/aws: Fix issue with SNS topic policy if omitted [GH-3777]
  * provider/aws: Support scratch volumes in `aws_ecs_task_definition` [GH-3810]
  * provider/aws: Treat `aws_ecs_service` w/ Status==INACTIVE as deleted [GH-3828]
  * provider/aws: Expand ~ to homedir in `aws_s3_bucket_object.source` [GH-3910]
  * provider/aws: Fix issue with updating the `aws_ecs_task_definition` where `aws_ecs_service` didn't wait for a new computed ARN [GH-3924]
  * provider/aws: Prevent crashing when deleting `aws_ecs_service` that is already gone [GH-3914]
  * provider/aws: Allow spaces in `aws_db_subnet_group.name` (undocumented in the API) [GH-3955]
  * provider/aws: Make VPC ID required on subnets [GH-4021]
  * provider/azure: Various bug fixes [GH-3695]
  * provider/digitalocean: Fix issue preventing SSH fingerprints from working [GH-3633]
  * provider/digitalocean: Fix the DigitalOcean Droplet 404 potential on refresh of state [GH-3768]
  * provider/openstack: Fix several issues causing unresolvable diffs [GH-3440]
  * provider/openstack: Safely delete security groups [GH-3696]
  * provider/openstack: Ignore order of `security_groups` in instance [GH-3651]
  * provider/vsphere: Fix d.SetConnInfo error in case of a missing IP address [GH-3636]
  * provider/openstack: Fix boot from volume [GH-3206]
  * provider/openstack: Fix crashing when image is no longer accessible [GH-2189]
  * provider/openstack: Better handling of network resource state changes [GH-3712]
  * provider/openstack: Fix crashing when no security group is specified [GH-3801]
  * provider/packet: Fix issue that could cause errors when provisioning many devices at once [GH-3847]
  * provider/packet: Fix connection information for devices, allowing provisioners to run [GH-3948]
  * provider/openstack: Fix issue preventing security group rules from being removed [GH-3796]
  * provider/template: `template_file`: source contents instead of path [GH-3909]

## 0.6.6 (October 23, 2015)

FEATURES:

  * New interpolation functions: `cidrhost`, `cidrnetmask` and `cidrsubnet` [GH-3127]

IMPROVEMENTS:

  * "forces new resource" now highlighted in plan output [GH-3136]

BUG FIXES:

  * helper/schema: Better error message for assigning list/map to string [GH-3009]
  * remote/state/atlas: Additional remote state conflict handling for semantically neutral state changes [GH-3603]

## 0.6.5 (October 21, 2015)

FEATURES:

  * **New resources: `aws_codeploy_app` and `aws_codeploy_deployment_group`** [GH-2783]
  * New remote state backend: `etcd` [GH-3487]
  * New interpolation functions: `upper` and `lower` [GH-3558]

BUG FIXES:

  * core: Fix remote state conflicts caused by ambiguity in ordering of deeply nested modules [GH-3573]
  * core: Fix remote state conflicts caused by state metadata differences [GH-3569]
  * core: Avoid using http.DefaultClient [GH-3532]

INTERNAL IMPROVEMENTS:

  * provider/digitalocean: use official Go client [GH-3333]
  * core: extract module fetching to external library [GH-3516]

## 0.6.4 (October 15, 2015)

FEATURES:

  * **New provider: `rundeck`** [GH-2412]
  * **New provider: `packet`** [GH-2260], [GH-3472]
  * **New provider: `vsphere`**: Initial support for a VM resource [GH-3419]
  * **New resource: `cloudstack_loadbalancer_rule`** [GH-2934]
  * **New resource: `google_compute_project_metadata`** [GH-3065]
  * **New resources: `aws_ami`, `aws_ami_copy`, `aws_ami_from_instance`** [GH-2784]
  * **New resources: `aws_cloudwatch_log_group`** [GH-2415]
  * **New resource: `google_storage_bucket_object`** [GH-3192]
  * **New resources: `google_compute_vpn_gateway`, `google_compute_vpn_tunnel`** [GH-3213]
  * **New resources: `google_storage_bucket_acl`, `google_storage_object_acl`** [GH-3272]
  * **New resource: `aws_iam_saml_provider`** [GH-3156]
  * **New resources: `aws_efs_file_system` and `aws_efs_mount_target`** [GH-2196]
  * **New resources: `aws_opsworks_*`** [GH-2162]
  * **New resource: `aws_elasticsearch_domain`** [GH-3443]
  * **New resource: `aws_directory_service_directory`** [GH-3228]
  * **New resource: `aws_autoscaling_lifecycle_hook`** [GH-3351]
  * **New resource: `aws_placement_group`** [GH-3457]
  * **New resource: `aws_glacier_vault`** [GH-3491]
  * **New lifecycle flag: `ignore_changes`** [GH-2525]

IMPROVEMENTS:

  * core: Add a function to find the index of an element in a list. [GH-2704]
  * core: Print all outputs when `terraform output` is called with no arguments [GH-2920]
  * core: In plan output summary, count resource replacement as Add/Remove instead of Change [GH-3173]
  * core: Add interpolation functions for base64 encoding and decoding. [GH-3325]
  * core: Expose parallelism as a CLI option instead of a hard-coding the default of 10 [GH-3365]
  * core: Add interpolation function `compact`, to remove empty elements from a list. [GH-3239], [GH-3479]
  * core: Allow filtering of log output by level, using e.g. ``TF_LOG=INFO`` [GH-3380]
  * provider/aws: Add `instance_initiated_shutdown_behavior` to AWS Instance [GH-2887]
  * provider/aws: Support IAM role names (previously just ARNs) in `aws_ecs_service.iam_role` [GH-3061]
  * provider/aws: Add update method to RDS Subnet groups, can modify subnets without recreating  [GH-3053]
  * provider/aws: Paginate notifications returned for ASG Notifications [GH-3043]
  * provider/aws: Adds additional S3 Bucket Object inputs [GH-3265]
  * provider/aws: add `ses_smtp_password` to `aws_iam_access_key` [GH-3165]
  * provider/aws: read `iam_instance_profile` for `aws_instance` and save to state [GH-3167]
  * provider/aws: allow `instance` to be computed in `aws_eip` [GH-3036]
  * provider/aws: Add `versioning` option to `aws_s3_bucket` [GH-2942]
  * provider/aws: Add `configuation_endpoint` to `aws_elasticache_cluster` [GH-3250]
  * provider/aws: Add validation for `app_cookie_stickiness_policy.name` [GH-3277]
  * provider/aws: Add validation for `db_parameter_group.name` [GH-3279]
  * provider/aws: Set DynamoDB Table ARN after creation [GH-3500]
  * provider/aws: `aws_s3_bucket_object` allows interpolated content to be set with new `content` attribute. [GH-3200]
  * provider/aws: Allow tags for `aws_kinesis_stream` resource. [GH-3397]
  * provider/aws: Configurable capacity waiting duration for ASGs [GH-3191]
  * provider/aws: Allow non-persistent Spot Requests [GH-3311]
  * provider/aws: Support tags for AWS DB subnet group [GH-3138]
  * provider/cloudstack: Add `project` parameter to `cloudstack_vpc`, `cloudstack_network`, `cloudstack_ipaddress` and `cloudstack_disk` [GH-3035]
  * provider/openstack: add functionality to attach FloatingIP to Port [GH-1788]
  * provider/google: Can now do multi-region deployments without using multiple providers [GH-3258]
  * remote/s3: Allow canned ACLs to be set on state objects. [GH-3233]
  * remote/s3: Remote state is stored in S3 with `Content-Type: application/json` [GH-3385]

BUG FIXES:

  * core: Fix problems referencing list attributes in interpolations [GH-2157]
  * core: don't error on computed value during input walk [GH-2988]
  * core: Ignore missing variables during destroy phase [GH-3393]
  * provider/google: Crashes with interface conversion in GCE Instance Template [GH-3027]
  * provider/google: Convert int to int64 when building the GKE cluster.NodeConfig struct [GH-2978]
  * provider/google: google_compute_instance_template.network_interface.network should be a URL [GH-3226]
  * provider/aws: Retry creation of `aws_ecs_service` if IAM policy isn't ready yet [GH-3061]
  * provider/aws: Fix issue with mixed capitalization for RDS Instances  [GH-3053]
  * provider/aws: Fix issue with RDS to allow major version upgrades [GH-3053]
  * provider/aws: Fix shard_count in `aws_kinesis_stream` [GH-2986]
  * provider/aws: Fix issue with `key_name` and using VPCs with spot instance requests [GH-2954]
  * provider/aws: Fix unresolvable diffs coming from `aws_elasticache_cluster` names being downcased
      by AWS [GH-3120]
  * provider/aws: Read instance source_dest_check and save to state [GH-3152]
  * provider/aws: Allow `weight = 0` in Route53 records [GH-3196]
  * provider/aws: Normalize aws_elasticache_cluster id to lowercase, allowing convergence. [GH-3235]
  * provider/aws: Fix ValidateAccountId for IAM Instance Profiles [GH-3313]
  * provider/aws: Update Security Group Rules to Version 2 [GH-3019]
  * provider/aws: Migrate KeyPair to version 1, fixing issue with using `file()` [GH-3470]
  * provider/aws: Fix force_delete on autoscaling groups [GH-3485]
  * provider/aws: Fix crash with VPC Peering connections [GH-3490]
  * provider/aws: fix bug with reading GSIs from dynamodb [GH-3300]
  * provider/docker: Fix issue preventing private images from being referenced [GH-2619]
  * provider/digitalocean: Fix issue causing unnecessary diffs based on droplet slugsize case [GH-3284]
  * provider/openstack: add state 'downloading' to list of expected states in
      `blockstorage_volume_v1` creation [GH-2866]
  * provider/openstack: remove security groups (by name) before adding security
      groups (by id) [GH-2008]

INTERNAL IMPROVEMENTS:

  * core: Makefile target "plugin-dev" for building just one plugin. [GH-3229]
  * helper/schema: Don't allow ``Update`` func if no attributes can actually be updated, per schema. [GH-3288]
  * helper/schema: Default hashing function for sets [GH-3018]
  * helper/multierror: Remove in favor of [github.com/hashicorp/go-multierror](http://github.com/hashicorp/go-multierror). [GH-3336]

## 0.6.3 (August 11, 2015)

BUG FIXES:

  * core: Skip all descendents after error, not just children; helps prevent confusing
      additional errors/crashes after initial failure [GH-2963]
  * core: fix deadlock possibility when both a module and a dependent resource are
      removed in the same run [GH-2968]
  * provider/aws: Fix issue with authenticating when using IAM profiles [GH-2959]

## 0.6.2 (August 6, 2015)

FEATURES:

  * **New resource: `google_compute_instance_group_manager`** [GH-2868]
  * **New resource: `google_compute_autoscaler`** [GH-2868]
  * **New resource: `aws_s3_bucket_object`** [GH-2898]

IMPROVEMENTS:

  * core: Add resource IDs to errors coming from `apply`/`refresh` [GH-2815]
  * provider/aws: Validate credentials before walking the graph [GH-2730]
  * provider/aws: Added website_domain for S3 buckets [GH-2210]
  * provider/aws: ELB names are now optional, and generated by Terraform if omitted [GH-2571]
  * provider/aws: Downcase RDS engine names to prevent continuous diffs [GH-2745]
  * provider/aws: Added `source_dest_check` attribute to the aws_network_interface [GH-2741]
  * provider/aws: Clean up externally removed Launch Configurations [GH-2806]
  * provider/aws: Allow configuration of the DynamoDB Endpoint [GH-2825]
  * provider/aws: Compute private ip addresses of ENIs if they are not specified [GH-2743]
  * provider/aws: Add `arn` attribute for DynamoDB tables [GH-2924]
  * provider/aws: Fail silently when account validation fails while from instance profile [GH-3001]
  * provider/azure: Allow `settings_file` to accept XML string [GH-2922]
  * provider/azure: Provide a simpler error when using a Platform Image without a
      Storage Service [GH-2861]
  * provider/google: `account_file` is now expected to be JSON. Paths are still supported for
      backwards compatibility. [GH-2839]

BUG FIXES:

  * core: Prevent error duplication in `apply` [GH-2815]
  * core: Fix crash when  a provider validation adds a warning [GH-2878]
  * provider/aws: Fix issue with toggling monitoring in AWS Instances [GH-2794]
  * provider/aws: Fix issue with Spot Instance Requests and cancellation [GH-2805]
  * provider/aws: Fix issue with checking for ElastiCache cluster cache node status [GH-2842]
  * provider/aws: Fix issue when unable to find a Root Block Device name of an Instance Backed
      AMI [GH-2646]
  * provider/dnsimple: Domain and type should force new records [GH-2777]
  * provider/aws: Fix issue with IAM Server Certificates and Chains [GH-2871]
  * provider/aws: Fix issue with IAM Server Certificates when using `path` [GH-2871]
  * provider/aws: Fix issue in Security Group Rules when the Security Group is not found [GH-2897]
  * provider/aws: allow external ENI attachments [GH-2943]
  * provider/aws: Fix issue with S3 Buckets, and throwing an error when not found [GH-2925]

## 0.6.1 (July 20, 2015)

FEATURES:

  * **New resource: `google_container_cluster`** [GH-2357]
  * **New resource: `aws_vpc_endpoint`** [GH-2695]

IMPROVEMENTS:

  * connection/ssh: Print SSH bastion host details to output [GH-2684]
  * provider/aws: Create RDS databases from snapshots [GH-2062]
  * provider/aws: Add support for restoring from Redis backup stored in S3 [GH-2634]
  * provider/aws: Add `maintenance_window` to ElastiCache cluster [GH-2642]
  * provider/aws: Availability Zones are optional when specifying VPC Zone Identifiers in
      Auto Scaling Groups updates [GH-2724]
  * provider/google: Add metadata_startup_script to google_compute_instance [GH-2375]

BUG FIXES:

  * core: Don't prompt for variables with defaults [GH-2613]
  * core: Return correct number of planned updates [GH-2620]
  * core: Fix "provider not found" error that can occur while running
      a destroy plan with grandchildren modules [GH-2755]
  * core: Fix UUID showing up in diff for computed splat (`foo.*.bar`)
      variables. [GH-2788]
  * core: Orphan modules that contain no resources (only other modules)
      are properly destroyed up to arbitrary depth [GH-2786]
  * core: Fix "attribute not available" during destroy plans in
      cases where the parameter is passed between modules [GH-2775]
  * core: Record schema version when destroy fails [GH-2923]
  * connection/ssh: fix issue on machines with an SSH Agent available
    preventing `key_file` from being read without explicitly
    setting `agent = false` [GH-2615]
  * provider/aws: Allow uppercase characters in `aws_elb.name` [GH-2580]
  * provider/aws: Allow underscores in `aws_db_subnet_group.name` (undocumented by AWS) [GH-2604]
  * provider/aws: Allow dots in `aws_db_subnet_group.name` (undocumented by AWS) [GH-2665]
  * provider/aws: Fix issue with pending Spot Instance requests [GH-2640]
  * provider/aws: Fix issue in AWS Classic environment with referencing external
      Security Groups [GH-2644]
  * provider/aws: Bump internet gateway detach timeout [GH-2669]
  * provider/aws: Fix issue with detecting differences in DB Parameters [GH-2728]
  * provider/aws: `ecs_cluster` rename (recreation) and deletion is handled correctly [GH-2698]
  * provider/aws: `aws_route_table` ignores routes generated for VPC endpoints [GH-2695]
  * provider/aws: Fix issue with Launch Configurations and enable_monitoring [GH-2735]
  * provider/openstack: allow empty api_key and endpoint_type [GH-2626]
  * provisioner/chef: Fix permission denied error with ohai hints [GH-2781]

## 0.6.0 (June 30, 2015)

BACKWARDS INCOMPATIBILITIES:

 * command/push: If a variable is already set within Atlas, it won't be
     updated unless the `-overwrite` flag is present [GH-2373]
 * connection/ssh: The `agent` field now defaults to `true` if
     the `SSH_AGENT_SOCK` environment variable is present. In other words,
     `ssh-agent` support is now opt-out instead of opt-in functionality. [GH-2408]
 * provider/aws: If you were setting access and secret key to blank ("")
     to force Terraform to load credentials from another source such as the
     EC2 role, this will now error. Remove the blank lines and Terraform
     will load from other sources.
 * `concat()` has been repurposed to combine lists instead of strings (old behavior
     of joining strings is maintained in this version but is deprecated, strings
     should be combined using interpolation syntax, like "${var.foo}{var.bar}")
     [GH-1790]

FEATURES:

  * **New provider: `azure`** [GH-2052, GH-2053, GH-2372, GH-2380, GH-2394, GH-2515, GH-2530, GH-2562]
  * **New resource: `aws_autoscaling_notification`** [GH-2197]
  * **New resource: `aws_autoscaling_policy`** [GH-2201]
  * **New resource: `aws_cloudwatch_metric_alarm`** [GH-2201]
  * **New resource: `aws_dynamodb_table`** [GH-2121]
  * **New resource: `aws_ecs_cluster`** [GH-1803]
  * **New resource: `aws_ecs_service`** [GH-1803]
  * **New resource: `aws_ecs_task_definition`** [GH-1803, GH-2402]
  * **New resource: `aws_elasticache_parameter_group`** [GH-2276]
  * **New resource: `aws_flow_log`** [GH-2384]
  * **New resource: `aws_iam_group_association`** [GH-2273]
  * **New resource: `aws_iam_policy_attachment`** [GH-2395]
  * **New resource: `aws_lambda_function`** [GH-2170]
  * **New resource: `aws_route53_delegation_set`** [GH-1999]
  * **New resource: `aws_route53_health_check`** [GH-2226]
  * **New resource: `aws_spot_instance_request`** [GH-2263]
  * **New resource: `cloudstack_ssh_keypair`** [GH-2004]
  * **New remote state backend: `swift`**: You can now store remote state in
     a OpenStack Swift. [GH-2254]
  * command/output: support display of module outputs [GH-2102]
  * core: `keys()` and `values()` funcs for map variables [GH-2198]
  * connection/ssh: SSH bastion host support and ssh-agent forwarding [GH-2425]

IMPROVEMENTS:

  * core: HTTP remote state now accepts `skip_cert_verification`
      option to ignore TLS cert verification. [GH-2214]
  * core: S3 remote state now accepts the 'encrypt' option for SSE [GH-2405]
  * core: `plan` now reports sum of resources to be changed/created/destroyed [GH-2458]
  * core: Change string list representation so we can distinguish empty, single
      element lists [GH-2504]
  * core: Properly close provider and provisioner plugin connections [GH-2406, GH-2527]
  * provider/aws: AutoScaling groups now support updating Load Balancers without
      recreation [GH-2472]
  * provider/aws: Allow more in-place updates for ElastiCache cluster without recreating
      [GH-2469]
  * provider/aws: ElastiCache Subnet Groups can be updated
      without destroying first [GH-2191]
  * provider/aws: Normalize `certificate_chain` in `aws_iam_server_certificate` to
      prevent unnecessary replacement. [GH-2411]
  * provider/aws: `aws_instance` supports `monitoring' [GH-2489]
  * provider/aws: `aws_launch_configuration` now supports `enable_monitoring` [GH-2410]
  * provider/aws: Show outputs after `terraform refresh` [GH-2347]
  * provider/aws: Add backoff/throttling during DynamoDB creation [GH-2462]
  * provider/aws: Add validation for aws_vpc.cidr_block [GH-2514]
  * provider/aws: Add validation for aws_db_subnet_group.name [GH-2513]
  * provider/aws: Add validation for aws_db_instance.identifier [GH-2516]
  * provider/aws: Add validation for aws_elb.name [GH-2517]
  * provider/aws: Add validation for aws_security_group (name+description) [GH-2518]
  * provider/aws: Add validation for aws_launch_configuration [GH-2519]
  * provider/aws: Add validation for aws_autoscaling_group.name [GH-2520]
  * provider/aws: Add validation for aws_iam_role.name [GH-2521]
  * provider/aws: Add validation for aws_iam_role_policy.name [GH-2552]
  * provider/aws: Add validation for aws_iam_instance_profile.name [GH-2553]
  * provider/aws: aws_auto_scaling_group.default_cooldown no longer requires
      resource replacement [GH-2510]
  * provider/aws: add AH and ESP protocol integers [GH-2321]
  * provider/docker: `docker_container` has the `privileged`
      option. [GH-2227]
  * provider/openstack: allow `OS_AUTH_TOKEN` environment variable
      to set the openstack `api_key` field [GH-2234]
  * provider/openstack: Can now configure endpoint type (public, admin,
      internal) [GH-2262]
  * provider/cloudstack: `cloudstack_instance` now supports projects [GH-2115]
  * provisioner/chef: Added a `os_type` to specifically specify the target OS [GH-2483]
  * provisioner/chef: Added a `ohai_hints` option to upload hint files [GH-2487]

BUG FIXES:

  * core: lifecycle `prevent_destroy` can be any value that can be
      coerced into a bool [GH-2268]
  * core: matching provider types in sibling modules won't override
      each other's config. [GH-2464]
  * core: computed provider configurations now properly validate [GH-2457]
  * core: orphan (commented out) resource dependencies are destroyed in
      the correct order [GH-2453]
  * core: validate object types in plugins are actually objects [GH-2450]
  * core: fix `-no-color` flag in subcommands [GH-2414]
  * core: Fix error of 'attribute not found for variable' when a computed
      resource attribute is used as a parameter to a module [GH-2477]
  * core: moduled orphans will properly inherit provider configs [GH-2476]
  * core: modules with provider aliases work properly if the parent
      doesn't implement those aliases [GH-2475]
  * core: unknown resource attributes passed in as parameters to modules
      now error [GH-2478]
  * core: better error messages for missing variables [GH-2479]
  * core: removed set items now properly appear in diffs and applies [GH-2507]
  * core: '*' will not be added as part of the variable name when you
      attempt multiplication without a space [GH-2505]
  * core: fix target dependency calculation across module boundaries [GH-2555]
  * command/*: fixed bug where variable input was not asked for unset
      vars if terraform.tfvars existed [GH-2502]
  * command/apply: prevent output duplication when reporting errors [GH-2267]
  * command/apply: destroyed orphan resources are properly counted [GH-2506]
  * provider/aws: loading credentials from the environment (vars, EC2 role,
      etc.) is more robust and will not ask for credentials from stdin [GH-1841]
  * provider/aws: fix panic when route has no `cidr_block` [GH-2215]
  * provider/aws: fix issue preventing destruction of IAM Roles [GH-2177]
  * provider/aws: fix issue where Security Group Rules could collide and fail
      to save to the state file correctly [GH-2376]
  * provider/aws: fix issue preventing destruction self referencing Securtity
     Group Rules [GH-2305]
  * provider/aws: fix issue causing perpetual diff on ELB listeners
      when non-lowercase protocol strings were used [GH-2246]
  * provider/aws: corrected frankfurt S3 website region [GH-2259]
  * provider/aws: `aws_elasticache_cluster` port is required [GH-2160]
  * provider/aws: Handle AMIs where RootBlockDevice does not appear in the
      BlockDeviceMapping, preventing root_block_device from working [GH-2271]
  * provider/aws: fix `terraform show` with remote state [GH-2371]
  * provider/aws: detect `instance_type` drift on `aws_instance` [GH-2374]
  * provider/aws: fix crash when `security_group_rule` referenced non-existent
      security group [GH-2434]
  * provider/aws: `aws_launch_configuration` retries if IAM instance
      profile is not ready yet. [GH-2452]
  * provider/aws: `fqdn` is populated during creation for `aws_route53_record` [GH-2528]
  * provider/aws: retry VPC delete on DependencyViolation due to eventual
      consistency [GH-2532]
  * provider/aws: VPC peering connections in "failed" state are deleted [GH-2544]
  * provider/aws: EIP deletion works if it was manually disassociated [GH-2543]
  * provider/aws: `elasticache_subnet_group.subnet_ids` is now a required argument [GH-2534]
  * provider/aws: handle nil response from VPN connection describes [GH-2533]
  * provider/cloudflare: manual record deletion doesn't cause error [GH-2545]
  * provider/digitalocean: handle case where droplet is deleted outside of
      terraform [GH-2497]
  * provider/dme: No longer an error if record deleted manually [GH-2546]
  * provider/docker: Fix issues when using containers with links [GH-2327]
  * provider/openstack: fix panic case if API returns nil network [GH-2448]
  * provider/template: fix issue causing "unknown variable" rendering errors
      when an existing set of template variables is changed [GH-2386]
  * provisioner/chef: improve the decoding logic to prevent parameter not found errors [GH-2206]

## 0.5.3 (June 1, 2015)

IMPROVEMENTS:

  * **New resource: `aws_kinesis_stream`** [GH-2110]
  * **New resource: `aws_iam_server_certificate`** [GH-2086]
  * **New resource: `aws_sqs_queue`** [GH-1939]
  * **New resource: `aws_sns_topic`** [GH-1974]
  * **New resource: `aws_sns_topic_subscription`** [GH-1974]
  * **New resource: `aws_volume_attachment`** [GH-2050]
  * **New resource: `google_storage_bucket`** [GH-2060]
  * provider/aws: support ec2 termination protection [GH-1988]
  * provider/aws: support for RDS Read Replicas [GH-1946]
  * provider/aws: `aws_s3_bucket` add support for `policy` [GH-1992]
  * provider/aws: `aws_ebs_volume` add support for `tags` [GH-2135]
  * provider/aws: `aws_elasticache_cluster` Confirm node status before reporting
      available
  * provider/aws: `aws_network_acl` Add support for ICMP Protocol [GH-2148]
  * provider/aws: New `force_destroy` parameter for S3 buckets, to destroy
      Buckets that contain objects [GH-2007]
  * provider/aws: switching `health_check_type` on ASGs no longer requires
      resource refresh [GH-2147]
  * provider/aws: ignore empty `vpc_security_group_ids` on `aws_instance` [GH-2311]

BUG FIXES:

  * provider/aws: Correctly handle AWS keypairs which no longer exist [GH-2032]
  * provider/aws: Fix issue with restoring an Instance from snapshot ID [GH-2120]
  * provider/template: store relative path in the state [GH-2038]
  * provisioner/chef: fix interpolation in the Chef provisioner [GH-2168]
  * provisioner/remote-exec: Don't prepend shebang on scripts that already
      have one [GH-2041]

## 0.5.2 (May 15, 2015)

FEATURES:

  * **Chef provisioning**: You can now provision new hosts (both Linux and
     Windows) with [Chef](https://chef.io) using a native provisioner [GH-1868]

IMPROVEMENTS:

  * **New config function: `formatlist`** - Format lists in a similar way to `format`.
    Useful for creating URLs from a list of IPs. [GH-1829]
  * **New resource: `aws_route53_zone_association`**
  * provider/aws: `aws_autoscaling_group` can wait for capacity in ELB
      via `min_elb_capacity` [GH-1970]
  * provider/aws: `aws_db_instances` supports `license_model` [GH-1966]
  * provider/aws: `aws_elasticache_cluster` add support for Tags [GH-1965]
  * provider/aws: `aws_network_acl` Network ACLs can be applied to multiple subnets [GH-1931]
  * provider/aws: `aws_s3_bucket` exports `hosted_zone_id` and `region` [GH-1865]
  * provider/aws: `aws_s3_bucket` add support for website `redirect_all_requests_to` [GH-1909]
  * provider/aws: `aws_route53_record` exports `fqdn` [GH-1847]
  * provider/aws: `aws_route53_zone` can create private hosted zones [GH-1526]
  * provider/google: `google_compute_instance` `scratch` attribute added [GH-1920]

BUG FIXES:

  * core: fix "resource not found" for interpolation issues with modules
  * core: fix unflattenable error for orphans [GH-1922]
  * core: fix deadlock with create-before-destroy + modules [GH-1949]
  * core: fix "no roots found" error with create-before-destroy [GH-1953]
  * core: variables set with environment variables won't validate as
      not set without a default [GH-1930]
  * core: resources with a blank ID in the state are now assumed to not exist [GH-1905]
  * command/push: local vars override remote ones [GH-1881]
  * provider/aws: Mark `aws_security_group` description as `ForceNew` [GH-1871]
  * provider/aws: `aws_db_instance` ARN value is correct [GH-1910]
  * provider/aws: `aws_db_instance` only submit modify request if there
      is a change. [GH-1906]
  * provider/aws: `aws_elasticache_cluster` export missing information on cluster nodes [GH-1965]
  * provider/aws: bad AMI on a launch configuration won't block refresh [GH-1901]
  * provider/aws: `aws_security_group` + `aws_subnet` - destroy timeout increased
    to prevent DependencyViolation errors. [GH-1886]
  * provider/google: `google_compute_instance` Local SSDs no-longer cause crash
      [GH-1088]
  * provider/google: `google_http_health_check` Defaults now driven from Terraform,
      avoids errors on update [GH-1894]
  * provider/google: `google_compute_template` Update Instance Template network
      definition to match changes to Instance [GH-980]
  * provider/template: Fix infinite diff [GH-1898]

## 0.5.1 (never released)

This version was never released since we accidentally skipped it!

## 0.5.0 (May 7, 2015)

BACKWARDS INCOMPATIBILITIES:

  * provider/aws: Terraform now remove the default egress rule created by AWS in
    a new security group.

FEATURES:

  * **Multi-provider (a.k.a multi-region)**: Multiple instances of a single
     provider can be configured so resources can apply to different settings.
     As an example, this allows Terraform to manage multiple regions with AWS.
  * **Environmental variables to set variables**: Environment variables can be
     used to set variables. The environment variables must be in the format
     `TF_VAR_name` and this will be checked last for a value.
  * **New remote state backend: `s3`**: You can now store remote state in
     an S3 bucket. [GH-1723]
  * **Automatic AWS retries**: This release includes a lot of improvement
     around automatic retries of transient errors in AWS. The number of
     retry attempts is also configurable.
  * **Templates**: A new `template_file` resource allows long strings needing
     variable interpolation to be moved into files. [GH-1778]
  * **Provision with WinRM**: Provisioners can now run remote commands on
     Windows hosts. [GH-1483]

IMPROVEMENTS:

  * **New config function: `length`** - Get the length of a string or a list.
      Useful in conjunction with `split`. [GH-1495]
  * **New resource: `aws_app_cookie_stickiness_policy`**
  * **New resource: `aws_customer_gateway`**
  * **New resource: `aws_ebs_volume`**
  * **New resource: `aws_elasticache_cluster`**
  * **New resource: `aws_elasticache_security_group`**
  * **New resource: `aws_elasticache_subnet_group`**
  * **New resource: `aws_iam_access_key`**
  * **New resource: `aws_iam_group_policy`**
  * **New resource: `aws_iam_group`**
  * **New resource: `aws_iam_instance_profile`**
  * **New resource: `aws_iam_policy`**
  * **New resource: `aws_iam_role_policy`**
  * **New resource: `aws_iam_role`**
  * **New resource: `aws_iam_user_policy`**
  * **New resource: `aws_iam_user`**
  * **New resource: `aws_lb_cookie_stickiness_policy`**
  * **New resource: `aws_proxy_protocol_policy`**
  * **New resource: `aws_security_group_rule`**
  * **New resource: `aws_vpc_dhcp_options_association`**
  * **New resource: `aws_vpc_dhcp_options`**
  * **New resource: `aws_vpn_connection_route`**
  * **New resource: `google_dns_managed_zone`**
  * **New resource: `google_dns_record_set`**
  * **Migrate to upstream AWS SDK:** Migrate the AWS provider to
      [awslabs/aws-sdk-go](https://github.com/awslabs/aws-sdk-go),
      the official `awslabs` library. Previously we had forked the library for
      stability while `awslabs` refactored. Now that work has completed, and we've
      migrated back to the upstream version.
  * core: Improve error message on diff mismatch [GH-1501]
  * provisioner/file: expand `~` in source path [GH-1569]
  * provider/aws: Better retry logic, now retries up to 11 times by default
      with exponentional backoff. This number is configurable. [GH-1787]
  * provider/aws: Improved credential detection [GH-1470]
  * provider/aws: Can specify a `token` via the config file [GH-1601]
  * provider/aws: Added new `vpc_security_group_ids` attribute for AWS
      Instances. If using a VPC, you can now modify the security groups for that
      Instance without destroying it [GH-1539]
  * provider/aws: White or blacklist account IDs that can be used to
      protect against accidents. [GH-1595]
  * provider/aws: Add a subset of IAM resources [GH-939]
  * provider/aws: `aws_autoscaling_group` retries deletes through "in progress"
      errors [GH-1840]
  * provider/aws: `aws_autoscaling_group` waits for healthy capacity during
      ASG creation [GH-1839]
  * provider/aws: `aws_instance` supports placement groups [GH-1358]
  * provider/aws: `aws_eip` supports network interface attachment [GH-1681]
  * provider/aws: `aws_elb` supports in-place changing of listeners [GH-1619]
  * provider/aws: `aws_elb` supports connection draining settings [GH-1502]
  * provider/aws: `aws_elb` increase default idle timeout to 60s [GH-1646]
  * provider/aws: `aws_key_pair` name can be omitted and generated [GH-1751]
  * provider/aws: `aws_network_acl` improved validation for network ACL ports
      and protocols [GH-1798] [GH-1808]
  * provider/aws: `aws_route_table` can target network interfaces [GH-968]
  * provider/aws: `aws_route_table` can specify propagating VGWs [GH-1516]
  * provider/aws: `aws_route53_record` supports weighted sets [GH-1578]
  * provider/aws: `aws_route53_zone` exports nameservers [GH-1525]
  * provider/aws: `aws_s3_bucket` website support [GH-1738]
  * provider/aws: `aws_security_group` name becomes optional and can be
      automatically set to a unique identifier; this helps with
      `create_before_destroy` scenarios [GH-1632]
  * provider/aws: `aws_security_group` description becomes optional with a
      static default value [GH-1632]
  * provider/aws: automatically set the private IP as the SSH address
      if not specified and no public IP is available [GH-1623]
  * provider/aws: `aws_elb` exports `source_security_group` field [GH-1708]
  * provider/aws: `aws_route53_record` supports alias targeting [GH-1775]
  * provider/aws: Remove default AWS egress rule for newly created Security Groups [GH-1765]
  * provider/consul: add `scheme` configuration argument [GH-1838]
  * provider/docker: `docker_container` can specify links [GH-1564]
  * provider/google: `resource_compute_disk` supports snapshots [GH-1426]
  * provider/google: `resource_compute_instance` supports specifying the
      device name [GH-1426]
  * provider/openstack: Floating IP support for LBaaS [GH-1550]
  * provider/openstack: Add AZ to `openstack_blockstorage_volume_v1` [GH-1726]

BUG FIXES:

  * core: Fix graph cycle issues surrounding modules [GH-1582] [GH-1637]
  * core: math on arbitrary variables works if first operand isn't a
      numeric primitive. [GH-1381]
  * core: avoid unnecessary cycles by pruning tainted destroys from
      graph if there are no tainted resources [GH-1475]
  * core: fix issue where destroy nodes weren't pruned in specific
      edge cases around matching prefixes, which could cause cycles [GH-1527]
  * core: fix issue causing diff mismatch errors in certain scenarios during
      resource replacement [GH-1515]
  * core: dependencies on resources with a different index work when
      count > 1 [GH-1540]
  * core: don't panic if variable default type is invalid [GH-1344]
  * core: fix perpetual diff issue for computed maps that are empty [GH-1607]
  * core: validation added to check for `self` variables in modules [GH-1609]
  * core: fix edge case where validation didn't pick up unknown fields
      if the value was computed [GH-1507]
  * core: Fix issue where values in sets on resources couldn't contain
      hyphens. [GH-1641]
  * core: Outputs removed from the config are removed from the state [GH-1714]
  * core: Validate against the worst-case graph during plan phase to catch cycles
      that would previously only show up during apply [GH-1655]
  * core: Referencing invalid module output in module validates [GH-1448]
  * command: remote states with uppercase types work [GH-1356]
  * provider/aws: Support `AWS_SECURITY_TOKEN` env var again [GH-1785]
  * provider/aws: Don't save "instance" for EIP if association fails [GH-1776]
  * provider/aws: launch configuration ID set after create success [GH-1518]
  * provider/aws: Fixed an issue with creating ELBs without any tags [GH-1580]
  * provider/aws: Fix issue in Security Groups with empty IPRanges [GH-1612]
  * provider/aws: manually deleted S3 buckets are refreshed properly [GH-1574]
  * provider/aws: only check for EIP allocation ID in VPC [GH-1555]
  * provider/aws: raw protocol numbers work in `aws_network_acl` [GH-1435]
  * provider/aws: Block devices can be encrypted [GH-1718]
  * provider/aws: ASG health check grace period can be updated in-place [GH-1682]
  * provider/aws: ELB security groups can be updated in-place [GH-1662]
  * provider/aws: `aws_main_route_table_association` can be deleted
      manually [GH-1806]
  * provider/docker: image can reference more complex image addresses,
      such as with private repos with ports [GH-1818]
  * provider/openstack: region config is not required [GH-1441]
  * provider/openstack: `enable_dhcp` for networking subnet should be bool [GH-1741]
  * provisioner/remote-exec: add random number to uploaded script path so
      that parallel provisions work [GH-1588]
  * provisioner/remote-exec: chmod the script to 0755 properly [GH-1796]

## 0.4.2 (April 10, 2015)

BUG FIXES:

  * core: refresh won't remove outputs from state file [GH-1369]
  * core: clarify "unknown variable" error [GH-1480]
  * core: properly merge parent provider configs when asking for input
  * provider/aws: fix panic possibility if RDS DB name is empty [GH-1460]
  * provider/aws: fix issue detecting credentials for some resources [GH-1470]
  * provider/google: fix issue causing unresolvable diffs when using legacy
      `network` field on `google_compute_instance` [GH-1458]

## 0.4.1 (April 9, 2015)

IMPROVEMENTS:

  * provider/aws: Route 53 records can now update `ttl` and `records` attributes
      without destroying/creating the record [GH-1396]
  * provider/aws: Support changing additional attributes of RDS databases
      without forcing a new resource  [GH-1382]

BUG FIXES:

  * core: module paths in ".terraform" are consistent across different
      systems so copying your ".terraform" folder works. [GH-1418]
  * core: don't validate providers too early when nested in a module [GH-1380]
  * core: fix race condition in `count.index` interpolation [GH-1454]
  * core: properly initialize provisioners, fixing resource targeting
      during destroy [GH-1544]
  * command/push: don't ask for input if terraform.tfvars is present
  * command/remote-config: remove spurrious error "nil" when initializing
      remote state on a new configuration. [GH-1392]
  * provider/aws: Fix issue with Route 53 and pre-existing Hosted Zones [GH-1415]
  * provider/aws: Fix refresh issue in Route 53 hosted zone [GH-1384]
  * provider/aws: Fix issue when changing map-public-ip in Subnets #1234
  * provider/aws: Fix issue finding db subnets [GH-1377]
  * provider/aws: Fix issues with `*_block_device` attributes on instances and
      launch configs creating unresolvable diffs when certain optional
      parameters were omitted from the config [GH-1445]
  * provider/aws: Fix issue with `aws_launch_configuration` causing an
      unnecessary diff for pre-0.4 environments [GH-1371]
  * provider/aws: Fix several related issues with `aws_launch_configuration`
      causing unresolvable diffs [GH-1444]
  * provider/aws: Fix issue preventing launch configurations from being valid
      in EC2 Classic [GH-1412]
  * provider/aws: Fix issue in updating Route 53 records on refresh/read. [GH-1430]
  * provider/docker: Don't ask for `cert_path` input on every run [GH-1432]
  * provider/google: Fix issue causing unresolvable diff on instances with
      `network_interface` [GH-1427]

## 0.4.0 (April 2, 2015)

BACKWARDS INCOMPATIBILITIES:

  * Commands `terraform push` and `terraform pull` are now nested under
    the `remote` command: `terraform remote push` and `terraform remote pull`.
    The old `remote` functionality is now at `terraform remote config`. This
    consolidates all remote state management under one command.
  * Period-prefixed configuration files are now ignored. This might break
    existing Terraform configurations if you had period-prefixed files.
  * The `block_device` attribute of `aws_instance` has been removed in favor
    of three more specific attributes to specify block device mappings:
    `root_block_device`, `ebs_block_device`, and `ephemeral_block_device`.
    Configurations using the old attribute will generate a validation error
    indicating that they must be updated to use the new fields [GH-1045].

FEATURES:

  * **New provider: `dme` (DNSMadeEasy)** [GH-855]
  * **New provider: `docker` (Docker)** - Manage container lifecycle
      using the standard Docker API. [GH-855]
  * **New provider: `openstack` (OpenStack)** - Interact with the many resources
      provided by OpenStack. [GH-924]
  * **New feature: `terraform_remote_state` resource** - Reference remote
      states from other Terraform runs to use Terraform outputs as inputs
      into another Terraform run.
  * **New command: `taint`** - Manually mark a resource as tainted, causing
      a destroy and recreate on the next plan/apply.
  * **New resource: `aws_vpn_gateway`** [GH-1137]
  * **New resource: `aws_elastic_network_interfaces`** [GH-1149]
  * **Self-variables** can be used to reference the current resource's
      attributes within a provisioner. Ex. `${self.private_ip_address}` [GH-1033]
  * **Continuous state** saving during `terraform apply`. The state file is
      continuously updated as apply is running, meaning that the state is
      less likely to become corrupt in a catastrophic case: terraform panic
      or system killing Terraform.
  * **Math operations** in interpolations. You can now do things like
      `${count.index + 1}`. [GH-1068]
  * **New AWS SDK:** Move to `aws-sdk-go` (hashicorp/aws-sdk-go),
      a fork of the official `awslabs` repo. We forked for stability while
      `awslabs` refactored the library, and will move back to the officially
      supported version in the next release.

IMPROVEMENTS:

  * **New config function: `format`** - Format a string using `sprintf`
      format. [GH-1096]
  * **New config function: `replace`** - Search and replace string values.
      Search can be a regular expression. See documentation for more
      info. [GH-1029]
  * **New config function: `split`** - Split a value based on a delimiter.
      This is useful for faking lists as parameters to modules.
  * **New resource: `digitalocean_ssh_key`** [GH-1074]
  * config: Expand `~` with homedir in `file()` paths [GH-1338]
  * core: The serial of the state is only updated if there is an actual
      change. This will lower the amount of state changing on things
      like refresh.
  * core: Autoload `terraform.tfvars.json` as well as `terraform.tfvars` [GH-1030]
  * core: `.tf` files that start with a period are now ignored. [GH-1227]
  * command/remote-config: After enabling remote state, a `pull` is
      automatically done initially.
  * providers/google: Add `size` option to disk blocks for instances. [GH-1284]
  * providers/aws: Improve support for tagging resources.
  * providers/aws: Add a short syntax for Route 53 Record names, e.g.
      `www` instead of `www.example.com`.
  * providers/aws: Improve dependency violation error handling, when deleting
      Internet Gateways or Auto Scaling groups [GH-1325].
  * provider/aws: Add non-destructive updates to AWS RDS. You can now upgrade
      `engine_version`, `parameter_group_name`, and `multi_az` without forcing
      a new database to be created.[GH-1341]
  * providers/aws: Full support for block device mappings on instances and
      launch configurations [GH-1045, GH-1364]
  * provisioners/remote-exec: SSH agent support. [GH-1208]

BUG FIXES:

  * core: module outputs can be used as inputs to other modules [GH-822]
  * core: Self-referencing splat variables are no longer allowed in
      provisioners. [GH-795][GH-868]
  * core: Validate that `depends_on` doesn't contain interpolations. [GH-1015]
  * core: Module inputs can be non-strings. [GH-819]
  * core: Fix invalid plan that resulted in "diffs don't match" error when
      a computed attribute was used as part of a set parameter. [GH-1073]
  * core: Fix edge case where state containing both "resource" and
      "resource.0" would ignore the latter completely. [GH-1086]
  * core: Modules with a source of a relative file path moving up
      directories work properly, i.e. "../a" [GH-1232]
  * providers/aws: manually deleted VPC removes it from the state
  * providers/aws: `source_dest_check` regression fixed (now works). [GH-1020]
  * providers/aws: Longer wait times for DB instances.
  * providers/aws: Longer wait times for route53 records (30 mins). [GH-1164]
  * providers/aws: Fix support for TXT records in Route 53. [GH-1213]
  * providers/aws: Fix support for wildcard records in Route 53. [GH-1222]
  * providers/aws: Fix issue with ignoring the 'self' attribute of a
      Security Group rule. [GH-1223]
  * providers/aws: Fix issue with `sql_mode` in RDS parameter group always
      causing an update. [GH-1225]
  * providers/aws: Fix dependency violation with subnets and security groups
      [GH-1252]
  * providers/aws: Fix issue with refreshing `db_subnet_groups` causing an error
      instead of updating state [GH-1254]
  * providers/aws: Prevent empty string to be used as default
      `health_check_type` [GH-1052]
  * providers/aws: Add tags on AWS IG creation, not just on update [GH-1176]
  * providers/digitalocean: Waits until droplet is ready to be destroyed [GH-1057]
  * providers/digitalocean: More lenient about 404's while waiting [GH-1062]
  * providers/digitalocean: FQDN for domain records in CNAME, MX, NS, etc.
      Also fixes invalid updates in plans. [GH-863]
  * providers/google: Network data in state was not being stored. [GH-1095]
  * providers/heroku: Fix panic when config vars block was empty. [GH-1211]

PLUGIN CHANGES:

  * New `helper/schema` fields for resources: `Deprecated` and `Removed` allow
      plugins to generate warning or error messages when a given attribute is used.

## 0.3.7 (February 19, 2015)

IMPROVEMENTS:

  * **New resources: `google_compute_forwarding_rule`, `google_compute_http_health_check`,
      and `google_compute_target_pool`** - Together these provide network-level
      load balancing. [GH-588]
  * **New resource: `aws_main_route_table_association`** - Manage the main routing table
      of a VPC. [GH-918]
  * **New resource: `aws_vpc_peering_connection`** [GH-963]
  * core: Formalized the syntax of interpolations and documented it
      very heavily.
  * core: Strings in interpolations can now contain further interpolations,
      e.g.: `foo ${bar("${baz}")}`.
  * provider/aws: Internet gateway supports tags [GH-720]
  * provider/aws: Support the more standard environmental variable names
      for access key and secret keys. [GH-851]
  * provider/aws: The `aws_db_instance` resource no longer requires both
      `final_snapshot_identifier` and `skip_final_snapshot`; the presence or
      absence of the former now implies the latter. [GH-874]
  * provider/aws: Avoid unnecessary update of `aws_subnet` when
      `map_public_ip_on_launch` is not specified in config. [GH-898]
  * provider/aws: Add `apply_method` to `aws_db_parameter_group` [GH-897]
  * provider/aws: Add `storage_type` to `aws_db_instance` [GH-896]
  * provider/aws: ELB can update listeners without requiring new. [GH-721]
  * provider/aws: Security group support egress rules. [GH-856]
  * provider/aws: Route table supports VPC peering connection on route. [GH-963]
  * provider/aws: Add `root_block_device` to `aws_db_instance` [GH-998]
  * provider/google: Remove "client secrets file", as it's no longer necessary
      for API authentication [GH-884].
  * provider/google: Expose `self_link` on `google_compute_instance` [GH-906]

BUG FIXES:

  * core: Fixing use of remote state with plan files. [GH-741]
  * core: Fix a panic case when certain invalid types were used in
      the configuration. [GH-691]
  * core: Escape characters `\"`, `\n`, and `\\` now work in interpolations.
  * core: Fix crash that could occur when there are exactly zero providers
      installed on a system. [GH-786]
  * core: JSON TF configurations can configure provisioners. [GH-807]
  * core: Sort `depends_on` in state to prevent unnecessary file changes. [GH-928]
  * core: State containing the zero value won't cause a diff with the
      lack of a value. [GH-952]
  * core: If a set type becomes empty, the state will be properly updated
      to remove it. [GH-952]
  * core: Bare "splat" variables are not allowed in provisioners. [GH-636]
  * core: Invalid configuration keys to sub-resources are now errors. [GH-740]
  * command/apply: Won't try to initialize modules in some cases when
      no arguments are given. [GH-780]
  * command/apply: Fix regression where user variables weren't asked [GH-736]
  * helper/hashcode: Update `hash.String()` to always return a positive index.
      Fixes issue where specific strings would convert to a negative index
      and be omitted when creating Route53 records. [GH-967]
  * provider/aws: Automatically suffix the Route53 zone name on record names. [GH-312]
  * provider/aws: Instance should ignore root EBS devices. [GH-877]
  * provider/aws: Fix `aws_db_instance` to not recreate each time. [GH-874]
  * provider/aws: ASG termination policies are synced with remote state. [GH-923]
  * provider/aws: ASG launch configuration setting can now be updated in-place. [GH-904]
  * provider/aws: No read error when subnet is manually deleted. [GH-889]
  * provider/aws: Tags with empty values (empty string) are properly
      managed. [GH-968]
  * provider/aws: Fix case where route table would delete its routes
      on an unrelated change. [GH-990]
  * provider/google: Fix bug preventing instances with metadata from being
      created [GH-884].

PLUGIN CHANGES:

  * New `helper/schema` type: `TypeFloat` [GH-594]
  * New `helper/schema` field for resources: `Exists` must point to a function
      to check for the existence of a resource. This is used to properly
      handle the case where the resource was manually deleted. [GH-766]
  * There is a semantic change in `GetOk` where it will return `true` if
      there is any value in the diff that is _non-zero_. Before, it would
      return true only if there was a value in the diff.

## 0.3.6 (January 6, 2015)

FEATURES:

  * **New provider: `cloudstack`**

IMPROVEMENTS:

  * **New resource: `aws_key_pair`** - Import a public key into AWS. [GH-695]
  * **New resource: `heroku_cert`** - Manage Heroku app certs.
  * provider/aws: Support `eu-central-1`, `cn-north-1`, and GovCloud. [GH-525]
  * provider/aws: `route_table` can have tags. [GH-648]
  * provider/google: Support Ubuntu images. [GH-724]
  * provider/google: Support for service accounts. [GH-725]

BUG FIXES:

  * core: temporary/hidden files that look like Terraform configurations
      are no longer loaded. [GH-548]
  * core: Set types in resources now result in deterministic states,
      resulting in cleaner plans. [GH-663]
  * core: fix issue where "diff was not the same" would come up with
      diffing lists. [GH-661]
  * core: fix crash where module inputs weren't strings, and add more
      validation around invalid types here. [GH-624]
  * core: fix error when using a computed module output as an input to
      another module. [GH-659]
  * core: map overrides in "terraform.tfvars" no longer result in a syntax
      error. [GH-647]
  * core: Colon character works in interpolation [GH-700]
  * provider/aws: Fix crash case when internet gateway is not attached
      to any VPC. [GH-664]
  * provider/aws: `vpc_id` is no longer required. [GH-667]
  * provider/aws: `availability_zones` on ELB will contain more than one
      AZ if it is set as such. [GH-682]
  * provider/aws: More fields are marked as "computed" properly, resulting
      in more accurate diffs for AWS instances. [GH-712]
  * provider/aws: Fix panic case by using the wrong type when setting
      volume size for AWS instances. [GH-712]
  * provider/aws: route table ignores routes with 'EnableVgwRoutePropagation'
      origin since those come from gateways. [GH-722]
  * provider/aws: Default network ACL ID and default security group ID
      support for `aws_vpc`. [GH-704]
  * provider/aws: Tags are not marked as computed. This introduces another
      issue with not detecting external tags, but this will be fixed in
      the future. [GH-730]

## 0.3.5 (December 9, 2014)

FEATURES:

 * **Remote State**: State files can now be stored remotely via HTTP,
     Consul, or HashiCorp's Atlas.
 * **New Provider: `atlas`**: Retrieve artifacts for deployment from
     HashiCorp's Atlas service.
 * New `element()` function to index into arrays

IMPROVEMENTS:

  * provider/aws: Support tenancy for aws\_instance
  * provider/aws: Support block devices for aws\_instance
  * provider/aws: Support virtual\_name on block device
  * provider/aws: Improve RDS reliability (more grace time)
  * provider/aws: Added aws\_db\_parameter\_group resource
  * provider/aws: Added tag support to aws\_subnet
  * provider/aws: Routes in RouteTable are optional
  * provider/aws: associate\_public\_ip\_address on aws\_launch\_configuration
  * provider/aws: Added aws\_network\_acl
  * provider/aws: Ingress rules in security groups are optional
  * provider/aws: Support termination policy for ASG
  * provider/digitalocean: Improved droplet size compatibility

BUG FIXES:

  * core: Fixed issue causing double delete. [GH-555]
  * core: Fixed issue with create-before-destroy not being respected in
      some circumstances.
  * core: Fixing issue with count expansion with non-homogenous instance
      plans.
  * core: Fix issue with referencing resource variables from resources
      that don't exist yet within resources that do exist, or modules.
  * core: Fixing depedency handling for modules
  * core: Fixing output handling [GH-474]
  * core: Fixing count interpolation in modules
  * core: Fixing multi-var without module state
  * core: Fixing HCL variable declaration
  * core: Fixing resource interpolation for without state
  * core: Fixing handling of computed maps
  * command/init: Fixing recursion issue [GH-518]
  * command: Validate config before requesting input [GH-602]
  * build: Fixing GOPATHs with spaces

MISC:

  * provider/aws: Upgraded to helper.Schema
  * provider/heroku: Upgraded to helper.Schema
  * provider/mailgun: Upgraded to helper.Schema
  * provider/dnsimple: Upgraded to helper.Schema
  * provider/cloudflare: Upgraded to helper.Schema
  * provider/digitalocean: Upgraded to helper.Schema
  * provider/google: Upgraded to helper.Schema

## 0.3.1 (October 21, 2014)

IMPROVEMENTS:

  * providers/aws: Support tags for security groups.
  * providers/google: Add "external\_address" to network attributes [GH-454]
  * providers/google: External address is used as default connection host. [GH-454]
  * providers/heroku: Support `locked` and `personal` booleans on organization
      settings. [GH-406]

BUG FIXES:

  * core: Remove panic case when applying with a plan that generates no
      new state. [GH-403]
  * core: Fix a hang that can occur with enough resources. [GH-410]
  * core: Config validation will not error if the field is being
      computed so the value is still unknown.
  * core: If a resource fails to create and has provisioners, it is
      marked as tainted. [GH-434]
  * core: Set types are validated to be sets. [GH-413]
  * core: String types are validated properly. [GH-460]
  * core: Fix crash case when destroying with tainted resources. [GH-412]
  * core: Don't execute provisioners in some cases on destroy.
  * core: Inherited provider configurations will be properly interpolated. [GH-418]
  * core: Refresh works properly if there are outputs that depend on resources
      that aren't yet created. [GH-483]
  * providers/aws: Refresh of launch configs and autoscale groups load
      the correct data and don't incorrectly recreate themselves. [GH-425]
  * providers/aws: Fix case where ELB would incorrectly plan to modify
      listeners (with the same data) in some cases.
  * providers/aws: Retry destroying internet gateway for some amount of time
      if there is a dependency violation since it is probably just eventual
      consistency (public facing resources being destroyed). [GH-447]
  * providers/aws: Retry deleting security groups for some amount of time
      if there is a dependency violation since it is probably just eventual
      consistency. [GH-436]
  * providers/aws: Retry deleting subnet for some amount of time if there is a
      dependency violation since probably asynchronous destroy events take
      place still. [GH-449]
  * providers/aws: Drain autoscale groups before deleting. [GH-435]
  * providers/aws: Fix crash case if launch config is manually deleted. [GH-421]
  * providers/aws: Disassociate EIP before destroying.
  * providers/aws: ELB treats subnets as a set.
  * providers/aws: Fix case where in a destroy/create tags weren't reapplied. [GH-464]
  * providers/aws: Fix incorrect/erroneous apply cases around security group
      rules. [GH-457]
  * providers/consul: Fix regression where `key` param changed to `keys. [GH-475]

## 0.3.0 (October 14, 2014)

FEATURES:

  * **Modules**: Configuration can now be modularized. Modules can live on
    GitHub, BitBucket, Git/Hg repos, HTTP URLs, and file paths. Terraform
    automatically downloads/updates modules for you on request.
  * **New Command: `init`**. This command initializes a Terraform configuration
    from an existing Terraform module (also new in 0.3).
  * **New Command: `destroy`**. This command destroys infrastructure
    created with `apply`.
  * Terraform will ask for user input to fill in required variables and
    provider configurations if they aren't set.
  * `terraform apply MODULE` can be used as a shorthand to quickly build
    infrastructure from a module.
  * The state file format is now JSON rather than binary. This allows for
    easier machine and human read/write. Old binary state files will be
    automatically upgraded.
  * You can now specify `create_before_destroy` as an option for replacement
    so that new resources are created before the old ones are destroyed.
  * The `count` metaparameter can now contain interpolations (such as
    variables).
  * The current index for a resource with a `count` set can be interpolated
    using `${count.index}`.
  * Various paths can be interpolated with the `path.X` variables. For example,
    the path to the current module can be interpolated using `${path.module}`.

IMPROVEMENTS:

  * config: Trailing commas are now allowed for the final elements of lists.
  * core: Plugins are loaded from `~/.terraform.d/plugins` (Unix) or
    `%USERDATA%/terraform.d/plugins` (Windows).
  * command/show: With no arguments, it will show the default state. [GH-349]
  * helper/schema: Can now have default values. [GH-245]
  * providers/aws: Tag support for most resources.
  * providers/aws: New resource `db_subnet_group`. [GH-295]
  * providers/aws: Add `map_public_ip_on_launch` for subnets. [GH-285]
  * providers/aws: Add `iam_instance_profile` for instances. [GH-319]
  * providers/aws: Add `internal` option for ELBs. [GH-303]
  * providers/aws: Add `ssl_certificate_id` for ELB listeners. [GH-350]
  * providers/aws: Add `self` option for security groups for ingress
      rules with self as source. [GH-303]
  * providers/aws: Add `iam_instance_profile` option to
      `aws_launch_configuration`. [GH-371]
  * providers/aws: Non-destructive update of `desired_capacity` for
      autoscale groups.
  * providers/aws: Add `main_route_table_id` attribute to VPCs. [GH-193]
  * providers/consul: Support tokens. [GH-396]
  * providers/google: Support `target_tags` for firewalls. [GH-324]
  * providers/google: `google_compute_instance` supports `can_ip_forward` [GH-375]
  * providers/google: `google_compute_disk` supports `type` to support disks
      such as SSDs. [GH-351]
  * provisioners/local-exec: Output from command is shown in CLI output. [GH-311]
  * provisioners/remote-exec: Output from command is shown in CLI output. [GH-311]

BUG FIXES:

  * core: Providers are validated even without a `provider` block. [GH-284]
  * core: In the case of error, walk all non-dependent trees.
  * core: Plugin loading from CWD works properly.
  * core: Fix many edge cases surrounding the `count` meta-parameter.
  * core: Strings in the configuration can escape double-quotes with the
      standard `\"` syntax.
  * core: Error parsing CLI config will show properly. [GH-288]
  * core: More than one Ctrl-C will exit immediately.
  * providers/aws: autoscaling_group can be launched into a vpc [GH-259]
  * providers/aws: not an error when RDS instance is deleted manually. [GH-307]
  * providers/aws: Retry deleting subnet for some time while AWS eventually
      destroys dependencies. [GH-357]
  * providers/aws: More robust destroy for route53 records. [GH-342]
  * providers/aws: ELB generates much more correct plans without extranneous
      data.
  * providers/aws: ELB works properly with dynamically changing
      count of instances.
  * providers/aws: Terraform can handle ELBs deleted manually. [GH-304]
  * providers/aws: Report errors properly if RDS fails to delete. [GH-310]
  * providers/aws: Wait for launch configuration to exist after creation
      (AWS eventual consistency) [GH-302]

## 0.2.2 (September 9, 2014)

IMPROVEMENTS:

  * providers/amazon: Add `ebs_optimized` flag. [GH-260]
  * providers/digitalocean: Handle 404 on delete
  * providers/digitalocean: Add `user_data` argument for creating droplets
  * providers/google: Disks can be marked `auto_delete`. [GH-254]

BUG FIXES:

  * core: Fix certain syntax of configuration that could cause hang. [GH-261]
  * core: `-no-color` flag properly disables color. [GH-250]
  * core: "~" is expanded in `-var-file` flags. [GH-273]
  * core: Errors with tfvars are shown in console. [GH-269]
  * core: Interpolation function calls with more than two args parse. [GH-282]
  * providers/aws: Refreshing EIP from pre-0.2 state file won't error. [GH-258]
  * providers/aws: Creating EIP without an instance/network won't fail.
  * providers/aws: Refreshing EIP manually deleted works.
  * providers/aws: Retry EIP delete to allow AWS eventual consistency to
      detect it isn't attached. [GH-276]
  * providers/digitalocean: Handle situations when resource was destroyed
      manually. [GH-279]
  * providers/digitalocean: Fix a couple scenarios where the diff was
      incorrect (and therefore the execution as well).
  * providers/google: Attaching a disk source (not an image) works
      properly. [GH-254]

## 0.2.1 (August 31, 2014)

IMPROVEMENTS:

  * core: Plugins are automatically discovered in the executable directory
      or pwd if named properly. [GH-190]
  * providers/mailgun: domain records are now saved to state

BUG FIXES:

  * core: Configuration parses when identifier and '=' have no space. [GH-243]
  * core: `depends_on` with `count` generates the proper graph. [GH-244]
  * core: Depending on a computed variable of a list type generates a
      plan without failure. i.e. `${type.name.foos.0.bar}` where `foos`
      is computed. [GH-247]
  * providers/aws: Route53 destroys in parallel work properly. [GH-183]

## 0.2.0 (August 28, 2014)

BACKWARDS INCOMPATIBILITIES:

  * We've replaced the configuration language in use from a C library to
    a pure-Go reimplementation. In the process, we removed some features
    of the language since it was too flexible:
    * Semicolons are no longer valid at the end of lines
    * Keys cannot be double-quoted strings: `"foo" = "bar"` is no longer
      valid.
    * JSON style maps `{ "foo": "bar" }` are no longer valid outside of JSON.
      Maps must be in the format of `{ foo = "bar" }` (like other objects
      in the config)
  * Heroku apps now require (will not validate without) `region` and
    `name` due to an upstream API change. [GH-239]

FEATURES:

  * **New Provider: `google`**: Manage Google Compute instances, disks,
      firewalls, and more.
  * **New Provider: `mailgun`**: Manage mailgun domains.
  * **New Function: `concat`**: Concatenate multiple strings together.
    Example: `concat(var.region, "-", var.channel)`.

IMPROVEMENTS:

  * core: "~/.terraformrc" (Unix) or "%APPDATA%/terraform.rc" (Windows)
    can be used to configure custom providers and provisioners. [GH-192]
  * providers/aws: EIPs now expose `allocation_id` and `public_ip`
      attributes.
  * providers/aws: Security group rules can be updated without a
      destroy/create.
  * providers/aws: You can enable and disable dns settings for VPCs. [GH-172]
  * providers/aws: Can specify a private IP address for `aws_instance` [GH-217]

BUG FIXES:

  * core: Variables are validated to not contain interpolations. [GH-180]
  * core: Key files for provisioning can now contain `~` and will be expanded
      to the user's home directory. [GH-179]
  * core: The `file()` function can load files in sub-directories. [GH-213]
  * core: Fix issue where some JSON structures didn't map properly into
     Terraform structures. [GH-177]
  * core: Resources with only `file()` calls will interpolate. [GH-159]
  * core: Variables work in block names. [GH-234]
  * core: Plugins are searched for in the same directory as the executable
      before the PATH. [GH-157]
  * command/apply: "tfvars" file no longer interferes with plan apply. [GH-153]
  * providers/aws: Fix issues around failing to read EIPs. [GH-122]
  * providers/aws: Autoscaling groups now register and export load
    balancers. [GH-207]
  * providers/aws: Ingress results are treated as a set, so order doesn't
      matter anymore. [GH-87]
  * providers/aws: Instance security groups treated as a set [GH-194]
  * providers/aws: Retry Route53 requests if operation failed because another
      operation is in progress [GH-183]
  * providers/aws: Route53 records with multiple record values work. [GH-221]
  * providers/aws: Changing AMI doesn't result in errors anymore. [GH-196]
  * providers/heroku: If you delete the `config_vars` block, config vars
      are properly nuked.
  * providers/heroku: Domains and drains are deleted before the app.
  * providers/heroku: Moved from the client library bgentry/heroku-go to
      cyberdelia/heroku-go [GH-239].
  * providers/heroku: Plans without a specific plan name for
      heroku\_addon work. [GH-198]

PLUGIN CHANGES:

  * **New Package:** `helper/schema`. This introduces a high-level framework
    for easily writing new providers and resources. The Heroku provider has
    been converted to this as an example.

## 0.1.1 (August 5, 2014)

FEATURES:

  * providers/heroku: Now supports creating Heroku Drains [GH-97]

IMPROVEMENTS:

  * providers/aws: Launch configurations accept user data [GH-94]
  * providers/aws: Regions are now validated [GH-96]
  * providers/aws: ELB now supports health check configurations [GH-109]

BUG FIXES:

  * core: Default variable file "terraform.tfvars" is auto-loaded. [GH-59]
  * core: Multi-variables (`foo.*.bar`) work even when `count = 1`. [GH-115]
  * core: `file()` function can have string literal arg [GH-145]
  * providers/cloudflare: Include the proper bins so the cloudflare
      provider is compiled
  * providers/aws: Engine version for RDS now properly set [GH-118]
  * providers/aws: Security groups now depend on each other and
  * providers/aws: DB instances now wait for destroys, have proper
      dependencies and allow passing skip_final_snapshot
  * providers/aws: Add associate_public_ip_address as an attribute on
      the aws_instance resource [GH-85]
  * providers/aws: Fix cidr blocks being updated [GH-65, GH-85]
  * providers/aws: Description is now required for security groups
  * providers/digitalocean: Private IP addresses are now a separate
      attribute
  * provisioner/all: If an SSH key is given with a password, a better
      error message is shown. [GH-73]

## 0.1.0 (July 28, 2014)

  * Initial release
