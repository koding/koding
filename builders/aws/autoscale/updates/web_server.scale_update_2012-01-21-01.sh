APP="web_server"
CFG="as_${APP}_cfg_0.1.0" # Launch config name
PATH_TO_USER_DATA="../user-data/${APP}-data.txt"
GRP="as_${APP}_grp" # Autoscale group name
SCALE_UP_POLICY="as_${APP}_policy" 
SCALE_DOWN_POLICY="as_${APP}_policy_scale_down"
ELB="as-webserver" # loadbalancer name
AMI="ami-3d4ff254" # Ubuntu 12.04 LTS
INSTANCE_TYPE="m1.small"
SSH_KEY="koding"
SNS_ARN="arn:aws:sns:us-east-1:616271189586:as-sns"
SEC_GRP="sg-b17399de"
VPC_SUBNET="subnet-dcd019b6" # 10.0.1.0/24 internal

#
# create email notifications

as-put-notification-configuration $GRP --topic-arn $SNS_ARN --notification-types autoscaling:EC2_INSTANCE_LAUNCH,autoscaling:EC2_INSTANCE_LAUNCH_ERROR,autoscaling:EC2_INSTANCE_TERMINATE,autoscaling:EC2_INSTANCE_TERMINATE_ERROR
