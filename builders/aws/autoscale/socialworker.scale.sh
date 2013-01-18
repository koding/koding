APP="socialworker"
CFG="as_${APP}_cfg_0.1.0" # Launch config name
PATH_TO_USER_DATA="../user-data/${APP}-data.txt"
GRP="as_${APP}_grp" # Autoscale group name
SCALE_UP_POLICY="as_${APP}_policy" 
SCALE_DOWN_POLICY="as_${APP}_policy_scale_down"
#ELB="as-webserver" # loadbalancer name
AMI="ami-3d4ff254" # Ubuntu 12.04 LTS
INSTANCE_TYPE="m1.small"
SSH_KEY="koding"
SNS_ARN="arn:aws:sns:us-east-1:616271189586:as-sns"
SEC_GRP="sg-b17399de"
VPC_SUBNET="subnet-dcd019b6" # 10.0.1.0/24 internal

#
as-create-launch-config $CFG --image-id $AMI --instance-type $INSTANCE_TYPE --key $SSH_KEY --group $SEC_GRP --user-data-file $PATH_TO_USER_DATA


#as-create-auto-scaling-group $GRP --min-size 2 --max-size 10 --vpc-zone-identifier $VPC_SUBNET --launch-configuration $CFG  --load-balancers $ELB
as-create-auto-scaling-group $GRP --min-size 2 --max-size 10 --vpc-zone-identifier $VPC_SUBNET --launch-configuration $CFG 


POLICY_UP_ARN=$(as-put-scaling-policy $SCALE_UP_POLICY --auto-scaling-group $GRP --adjustment=1 --type ChangeInCapacity --cooldown 300)


mon-put-metric-alarm ${APP}_HighCPUAlarm  --comparison-operator  GreaterThanThreshold  --evaluation-periods  1 --metric-name  CPUUtilization  --namespace  "AWS/EC2"  --period  300  --statistic Average --threshold  80 --alarm-actions $POLICY_UP_ARN --dimensions "AutoScalingGroupName=${GRP}"

POLICY_DOWN_ARN=$(as-put-scaling-policy $SCALE_DOWN_POLICY --auto-scaling-group $GRP  --adjustment=-1 --type ChangeInCapacity  --cooldown 300)

mon-put-metric-alarm ${APP}_LowCPUAlarm  --comparison-operator  LessThanThreshold --evaluation-periods  1 --metric-name  CPUUtilization --namespace  "AWS/EC2"  --period  600  --statistic Average --threshold  40  --alarm-actions $POLICY_DOWN_ARN --dimensions "AutoScalingGroupName=${GRP}"



