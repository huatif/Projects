buil-stacker.sh
# Environments file
# App settings:
app_name: EC2_TST
component_name:Windows
 
# Environment settings
aws_account: dev
env_name: dev

instance_ami: ami-0a20ff67885e5cfc4
 
 
 
hostname: win2016-ec2
app_version: 2019
# dns_hostname: cinchydev
instance_type: t2.micro
ops_bucket_name: cix-ops-dev
iam_role_name: CinchyApp-S3-Installer-Download
ec2_keypair: Win-AMI-Keypair
RootVolumeSize: 40
app_name: dev