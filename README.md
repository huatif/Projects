




## **Table of Contents**

  1. [Description](#Description)
  2. [Prerequisites](#Prerequisites)
  3. [Account Creation and Configuration](#IWMS_Account)
  4. [Create an IAM User with Programmatic Access](#IAMUser)
  5. [Enabling SAML Federated Single Sign-On](#SAML)
  6. [Create an IAM Role on the Shared Account for VPC Peering](#VPCPeeringRole)   
  7. [Deploy Template to Create Network Infrastructure](#NetworkInfrastructure)
  8. [Deploy Template to Create the Private DNS Zone](#PrivateDNS)
  9. [Customizing Account Alias ](#AccountAliasName)
  10. [Deploy AWS Cli Scripts ](#AWSCli)
 
       1.  [Createing & Associating Virtal Interface for the New Account   ](#VIF)
       2.  [Enable DNS Support for VPC peering](#DNSSupport)
       3.  [Updating the Route Tables of the `Shared Account](#UpdateRT)
       4.  [Updating the Network ACL](#UpdateACL)
       5.  [Creating VPC Association Authorization](#VPCAuthorization)
       6.  [Creating VPC Association with the DNS Hosted-Zone](#VPCAssociation)
       7.  [Imporating SSL Certificate into ACM](#SSL)
  11. [On-Prem Tasks](#OnPrem)
  12. [Security Requirements](#InfoSec)

<a name="Description"></a>
## 1. **Description** 

This document was created during the creation of IWMS accounts which includes all the tasks that were applied to all 3 accounts for IWMS team.

All the Cloudformation templates are stored in the CI bitbucket repository here [IWMS-CFN](https://bitbucket.corporate.ciglobe.net/projects/AWSI/repos/iwms-cfn/browse?at=refs%2Fheads%2Ffeature%2FAWSID-374).


All the Cloudformation templates and AWS CLI scripts that were used to create and configure AWS accounts for IWMS team. Some of the information were provided by the network team, InfoSec team and Change Management.


<a name="Prerequisites"></a>
## 2. **Prerequisites**
Following are the required information.

**1. Account Names and E-Mail Addresses**

|  Account Names   | E-mail addresses| 
|:-----------------|:------------------:|
| ci-iwms-dev      |aws_iwms_devel@ci.com |
| ci-iwms-uat      |aws_iwms_uat@ci.com   |
| ci-iwms-prod     |aws_iwms_prod@ci.com  |


**2. CIDR Block addresses for the VPCs (By Network Team)**


|   Resources        | iwms-dev      | iwms-uat      | iwms-prod     |
|:------------------:|:-------------:|:-------------:| :------------:|
| CIDR Block         |10.106.0.0/16  |10.107.0.0/16  |10.108.0.0/16  |

**3. Direct Connect Configurations (By Network Team)**

    Send a request to the "Network Team" to provide you with these information for Direct Connect. You would need these information for CloudFormation template parameters.

|   Resources           | iwms-dev      | iwms-uat      | iwms-prod     |
|:---------------------:|:-------------:|:-------------:| :------------:|
|Subnets:               |10.10.0.40/30  |10.10.0.44/30  |10.10.0.48/30  |
|AWS Address:           |10.10.0.41     | 10.10.0.45    |10.10.0.49     |
|CI Address             |10.10.0.42     | 10.10.0.46    |10.10.0.50     |
|VLAN ID                |  3771         |   3572        |  3573         |

<a name="IWMS_Account"></a>
## 3. **Account Creation and Configuration**

#### Steps for Creating/Configuring the IWMS Accounts (This is a manual task)

#### 1.  Creating a new Account
  - Login to the Master Account with admin access
  - On the `Accounts` tab, choose `Add Account`
  - Choose `create Account`
  - Enter the name and email address of the account as mentioned under `Description` section.   - (Optional) Enter an IAM RoleName. If you don't speicify a role name, AWS Organization gives the role a default name of `OrganizationAccountAccessRole`.
    
#### 2.  Reset the Password for the Account
   - Browse to [AWS Management console](https://aws.amazon.com/console), reset the password for the root account since this is the first using the root account. 
   - Click Sign-In to the Console.
   - Enter the email address of the account under the account ID, then click `forgot password` to follow the process.

<a name="IAMUser"></a>

## 4.  **Create an IAM User with Programmatic Access**
   This user account will be used for deploying the CloudFormation templates. At the end of project, this account would no longer be rerquired and will be removed.

   - Login to [AWS Management console](https://aws.amazon.com/console) using the root account.
   - From the IAM console, choose Users.
   - Choose `Add user` 
   - Enter a name for the user and select `Programmatic access` under the  Access type.
   - Click `Next` and choose `Attach existing policies directly`
   - Choose `AdministratorAccess` policy.
   - Click `Next Next` and `Create user`.

<a name="SAML"></a>

 ## 5. **Enabling SAML Federated Single Sign-On**

The following `two` templates deploy an Identity Provider and IAM Roles for SAML authentication.

1. Deploy ``saml-idp.cfn.yaml`` template to create an Identity Provider called `ADFS`. This downloads the ADFS Metadata called `SAMl-Metadata.xml` from the S3 Bucket specified in this template.

```batch
aws cloudformation create-stack --template-body file://saml-idp.yaml --stack-name SAML-IDP --capabilities CAPABILITY_NAMED_IAM
```

2. Deploy `roles.cfn.yaml` template to create the following IAM roles for SAML authentication. 

     - ADFSAdmin
     - ADFSAdministrators
     - ADFSChangeManagement
     - ADFSDevelopers
     - ADFSQA
     - ADFSSecurity

```batch
aws cloudformation create-stack --template-body file://roles.cfn.yam --stack-name SAML-Roles --capabilities CAPABILITY_NAMED_IAM
```
 3. Create the following ADFS Groups on On-prem Active Directory if these are not already created. These will be created by IT Admin team at IT Services. `AccountNumber` represents the Account ID of the account.

      - AWS-`accountNumber`-ADFSAdmin
      - AWS-`accountNumber`-ADFSAdministrators
      - AWS-`accountNumber`-ADFSBilling
      - AWS-`accountNumber`-ADFSChangeManagement
      - AWS-`accountNumber`-ADFSDevelopers
      - AWS-`accountNumber`-ADFSOperations
      - AWS-`accountNumber`-ADFSQA
      - AWS-`accountNumber`-ADFSSecurity
      
**At this point, you should have federated access working**.

## **Deploying CloudFormation Templates**

<a name="VPCPeeringRole"></a>
## 6. **Create an IAM Role on the Shared Account for VPC Peering**

   - Login to the `Shared Account` with Federated Access.
   - Deploy `peering-iamrole-accepter.yaml` template to create an IAM role for creating and accepting VPC Peering connection. 
 - Specify `ARN` of the role in the `network.paramters.xxx.json` file.


**For IWMS DEV**
```batch
aws cloudformation create-stack --template-body file://peering-iamrole-accepter.yaml --stack-name iwms-dev-VPCPeering-role --parameters ParameterKey=PeerRequesterAccountId,ParameterValue=797026961867 --capabilities CAPABILITY_NAMED_IAM
```

**For IWMS UAT**
```batch
aws cloudformation create-stack --template-body file://peering-iamrole-accepter.yaml --stack-name iwms-uat-VPCPeering-role --parameters ParameterKey=PeerRequesterAccountId,ParameterValue=154576756847 --capabilities CAPABILITY_NAMED_IAM
```
**For IWMS Prod**
```batch
aws cloudformation create-stack --template-body file://peering-iamrole-accepter.yaml --stack-name iwms-prod-VPCPeering-role --parameters ParameterKey=PeerRequesterAccountId,ParameterValue=633969933150 --capabilities CAPABILITY_NAMED_IAM
```

<a name="NetworkInfrastructure"></a>
## 7. **Deploying Template to Create Network Infrastructure**

- Upload `network.cfn.yaml` template to S3 bucket.
- Deploy `network.cfn.yaml` with the respective parameter .JSON file - `network.parameter.cfn.xxxxxxxx.json`.

#### This Stack creates the following resources.

  - A custom VPC.
  - Six Subnets.
  - Internet Gateway.
  - DHCP Options Set for `aws.ciglobe.net` AD Domain Controllers
  - Two Elastic IPs.
  - Two NAT Gateways
  - VPC Peering request to the Shared account.
  - VPC Peering for Shared Account to accept.
  - Six Security Groups.
  - Three Network Access Control Lists (ACL).
  - Customer Gateway with IP address: `198.163.239.154`, BGP ASN: `65000`.
  - Virtual Private Gateway (VPG).
  - Site-to-Site VPN Connection.
    

`Note:`  This stack uses the S3 bucket to download the template, so make sure `network.cfn.yaml` template has alreayd been uploaded to the S3 bucket for the environment you are working on. 

**IWMS DEV**
```batch
aws cloudformation create-stack --stack-name NetworkInfrastructure --s3-bucket saml-metadata-uz4uurooqu9shefo --template-file network.cfn.yaml --parameters file://network.parameters.dev.json --capabilities CAPABILITY_NAMED_IAM
```
**IWMS UAT**
```batch
aws cloudformation create-stack --stack-name NetworkInfrastructure --s3-bucket saml-metadata-uat --template-file network.cfn.yaml --parameters file://network.parameters.uat.json --capabilities CAPABILITY_NAMED_IAM
```
**IWMS PROD**
```batch
aws cloudformation create-stack --stack-name NetworkInfrastructure --s3-bucket saml-metadata-prod --template-file network.cfn.yaml --parameters file://network.parameters.prod.json --capabilities CAPABILITY_NAMED_IAM
```
<a name="PrivateDNS"></a>
## 8.  **Deploying Private DNS Zone (Route 53) template**

Depoly `dns-cfn.yaml` Cloudformation template with the parameter .JSON file `dns.parameter.cfn.xxx.json`. Following are teh AWS Cli scripts that can be used to create the DNS hosted zone for the environment, you are working on. 

This creates the `dev.iwms.aws.ciglobe.net` hosted zone.

***iwms-dev***

```batch
aws cloudformation create-stack --template-body file://dns.cfn.yaml --parameters file://dns.parameter.dev.cfn.json --stack-name PrivateDNS --capabilities CAPABILITY_NAMED_IAM
```

***iwms-uat***

This creates `uat.iwms.aws.ciglobe.net` hosted zone.
```batch

aws cloudformation create-stack --template-body file://dns.cfn.yaml --parameters file://dns.parameter.uat.cfn.json --stack-name PrivateDNS --capabilities CAPABILITY_NAMED_IAM
```

***iwms-pod***

This creates `prod.iwms.aws.ciglobe.net` hosted zone.

```batch
aws cloudformation create-stack --template-body file://dns.cfn.yaml --parameters file://dns.parameter.prod.cfn.json --stack-name PrivateDNS --capabilities CAPABILITY_NAMED_IAM
```

<a name="AccountAliasName"></a>
## 9. **Customizing Account Alias**

   - From the IAM Console Dashboard, click `customize` then set alias name as:
     `ci-iwms-dev` `ci-iwms-uat` `ci-iwms-prod` based on the environment you are working on.

<a name="AWSCli"></a>

## 10. **Deploying AWS CLI Scripts**

<a name="VIF"></a>
#### 1.  Createing & Associating Virtal Interface for the New Account.
These are AWS CLI scripts used to create and associate the Virtual Interface for Direct Connect from the new accounts. Each account has its own Amazon Side-ASN provided by network team.

 ***IWMS DEV***

1. This script creates the VIF in the `dev` account, ASN number and authentication Key need to be updared in the script.
```batch
aws directconnect create-private-virtual-interface --connection-id dxcon-fgzebi0g --new-private-virtual-interface virtualInterfaceName=VIF-iwms-dev,vlan=3571,asn=xxxxx,authKey=xxxxx,amazonAddress=10.0.0.41/30,customerAddress=10.0.0.42/30,addressFamily=ipv4
```
2. This script associates the `Direct Connect Gateway` with the Virtual Interface in the `dev` account:

```batch
aws directconnect create-direct-connect-gateway --direct-connect-gateway-name "DXG-iwms-prod" --amazon-side-asn xxxxx
```

***IWMS UAT***
1. This script creates the VIF in the `uat` account:
```batch
aws directconnect create-private-virtual-interface --connection-id dxcon-fgzebi0g --new-private-virtual-interface virtualInterfaceName=VIF-iwms-uat,vlan=3572,asn=xxxxx,authKey=xxxxx,amazonAddress=10.0.0.45/30,customerAddress=10.0.0.46/30,addressFamily=ipv4
```
2. This script associates the `Direct Connect Gateway` in the `uat` account:
```batch
aws directconnect create-direct-connect-gateway --direct-connect-gateway-name "DXG-iwms-prod" --amazon-side-asn xxxxxx
```

***IWMS PROD***
1. This script creates the VIF in the `prod` account:

```batch
aws directconnect create-private-virtual-interface --connection-id dxcon-fgzebi0g --new-private-virtual-interface virtualInterfaceName=VIF-iwms-uat,vlan=3573,asn=xxxxx,authKey=xxxxxx,amazonAddress=10.0.0.49/30,customerAddress=10.0.0.50/30,addressFamily=ipv4
```

2. This script associates the `Direct Connect Gateway` in the `prod` account:
```batch
aws directconnect create-direct-connect-gateway --direct-connect-gateway-name "DXG-iwms-prod" --amazon-side-asn xxxxx
```

**Output for the Direct Connect Association in the Prod environment**

```batch

{
    "directConnectGateway": {
        "directConnectGatewayId": "44ae5cdf-689a-4602-b8a5-3ba920385343",
        "directConnectGatewayName": "DXG-iwms-prod",
        "amazonSideAsn": xxxxxx,
        "ownerAccount": "633969933150",
        "directConnectGatewayState": "available"
    }
}
```

<a name="DNSSupport"></a>
#### 2. Enable DNS Support for VPC peering

 This command enables the DNS Support on the VPC Peering from the `REQUESTER and ACCEPTER` accounts. `Requester` is the new account, and `Accepter` is the CI Shared account.

**Requester account** To be run on the new account. `pcx-xxxxxxxx' ID needs to be updated in the script after creating the VPC Peering for the environment you are working on.

```batch
aws ec2 modify-vpc-peering-connection-options --vpc-peering-connection-id pcx-XXXXXXXXXXXXXXX --requester-peering-connection-options AllowDnsResolutionFromRemoteVpc=true
```
**Accepter Account**  To be run in the CI Shared Account.
```batch
aws ec2 modify-vpc-peering-connection-options --vpc-peering-connection-id pcx-XXXXXXXXXXXXXXX --accepter-peering-connection-options AllowDnsResolutionFromRemoteVpc=true
```
**Output Result**
You should get similar to this result:
```shell
{
    "RequesterPeeringConnectionOptions": {
        "AllowDnsResolutionFromRemoteVpc": true
    }
}
```
<a name="UpdateRT"></a>
#### 3. Updating the Route Tables of the `Shared Account`

VPC CIDR block addresses for the new accounts need to be added to the Route Tables of the `CI Shared Account` with the VPC peering target. Following AWS Cli scripts are for each account that need to be run from the `CI Shared Account`.

| iwms-dev | iwms-uat | iwms-prod |
|:-------------:|:-------------:| :------------:|
|10.106.0.0/16  |10.107.0.0/16  |10.108.0.0/16  |

***for iwms dev***
```batch
aws ec2 create-route --route-table-id rtb-07b76a4c107a7bf58 --destination-cidr-block 10.106.0.0/16 --vpc-peering-connection-id	pcx-0ac23e95c0d733d61
aws ec2 create-route --route-table-id rtb-0847e11965f6d79db --destination-cidr-block 10.106.0.0/16 --vpc-peering-connection-id pcx-0ac23e95c0d733d61
aws ec2 create-route --route-table-id rtb-0a7bc0378018f27fc --destination-cidr-block 10.106.0.0/16 --vpc-peering-connection-id pcx-0ac23e95c0d733d61
aws ec2 create-route --route-table-id rtb-0e729272df9aa40e0 --destination-cidr-block 10.106.0.0/16 --vpc-peering-connection-id pcx-0ac23e95c0d733d61
```

***for iwms uat***
```batch
aws ec2 create-route --route-table-id rtb-07b76a4c107a7bf58 --destination-cidr-block 10.107.0.0/16 --vpc-peering-connection-id pcx-0879cef1f0100e25f
aws ec2 create-route --route-table-id rtb-0847e11965f6d79db --destination-cidr-block 10.107.0.0/16 --vpc-peering-connection-id pcx-0879cef1f0100e25f
aws ec2 create-route --route-table-id rtb-0a7bc0378018f27fc --destination-cidr-block 10.107.0.0/16 --vpc-peering-connection-id pcx-0879cef1f0100e25f
aws ec2 create-route --route-table-id rtb-0e729272df9aa40e0 --destination-cidr-block 10.107.0.0/16 --vpc-peering-connection-id pcx-0879cef1f0100e25f
```

***for iwms prod***
```batch
aws ec2 create-route --route-table-id rtb-07b76a4c107a7bf58 --destination-cidr-block 10.108.0.0/16 --vpc-peering-connection-id pcx-00d767bdcb06bf43d
aws ec2 create-route --route-table-id rtb-0847e11965f6d79db --destination-cidr-block 10.108.0.0/16 --vpc-peering-connection-id pcx-00d767bdcb06bf43d
aws ec2 create-route --route-table-id rtb-0a7bc0378018f27fc --destination-cidr-block 10.108.0.0/16 --vpc-peering-connection-id pcx-00d767bdcb06bf43d
aws ec2 create-route --route-table-id rtb-0e729272df9aa40e0 --destination-cidr-block 10.108.0.0/16 --vpc-peering-connection-id pcx-00d767bdcb06bf43d
```
<a name="UpdateACL"></a>
#### 4. Updating Network ACL: 

This was not part of the CloudFormation template and may not be required, but this was added in DEV environment, so AWs ClI was used to add the same 500 rule to the ACLs on UAT and Prod accounts.

This setting is for Network ACL `NetworkInfrastructure/NetworkACLApplication` in each IWMS account.

***for iwms Dev***
```batch
aws ec2 create-network-acl-entry --network-acl-id acl-0a578317cbc755507 --ingress --rule-number 500 --protocol -1 --cidr-block 0.0.0.0/0 --rule-action allow
```
***for iwms uat***
```batch
aws ec2 create-network-acl-entry --network-acl-id acl-078a83552c91ace26 --egress --rule-number 500 --protocol -1 --cidr-block 0.0.0.0/0 --rule-action allow
```

***for iwms Prod***
```batch
aws ec2 create-network-acl-entry --network-acl-id acl-0a578317cbc755507 --egress --rule-number 500 --protocol -1 --cidr-block 0.0.0.0/0 --rule-action allow
```

<a name="VPCAuthorization"></a>
#### 5. Creating VPC Association Authorization
This authorizes the new IWMS account to submit an `AssociateVPCWithHostedZone` request to the `CI Shared` account to associate the VPC with the hosted zone of the new accounts.

- Login to the Shared Account and run these templates respectively for each account.

    -  Hosted-Zone specified is for the new account.
    -  VPC-ID specified is for the Shared Account. `vpc-0befb9df43910130c`

***iwms-dev***

```batch

aws route53 create-vpc-association-authorization --hosted-zone-id Z32RG3NV8U3O7X --vpc VPCRegion=ca-central-1,VPCId=vpc-0befb9df43910130c
```

***iwms-uat***

```batch
aws route53 create-vpc-association-authorization --hosted-zone-id Z2PCM3SWE3ZUAZ --vpc VPCRegion=ca-central-1,VPCId=vpc-0befb9df43910130c
```

***iwms-prod***

```batch
aws route53 create-vpc-association-authorization --hosted-zone-id Z24O1NYO9AUCZB --vpc VPCRegion=ca-central-1,VPCId=vpc-0befb9df43910130c
```

**Output Result for Authorization**
```
{
    "HostedZoneId": "Z24O1NYO9AUCZB",
    "VPC": {
        "VPCRegion": "ca-central-1",
        "VPCId": "vpc-0befb9df43910130c"
    }
}

```
<a name="VPCAssociation"></a>
#### 6. Associate VPC with the DNS Hosted-Zone

Since VPC association is authorized from the previous step, now we need to associate the VPC with the hosted-zone of the new account.

- Login to each new accounts and run these templates respectively.

    -  Hosted-Zone specified is for the new account.
    -  VPC-ID specified is for the Shared Account. `vpc-0befb9df43910130c`


***iwms-dev***
```batch
aws route53 associate-vpc-with-hosted-zone --hosted-zone-id Z32RG3NV8U3O7X --vpc VPCRegion=ca-central-1,VPCId=vpc-0befb9df43910130c
```
***iwms-uat***

```batch
aws route53 associate-vpc-with-hosted-zone --hosted-zone-id Z2PCM3SWE3ZUAZ --vpc VPCRegion=ca-central-1,VPCId=vpc-0befb9df43910130c
```

***iwms-prod***
```batch
aws route53 associate-vpc-with-hosted-zone --hosted-zone-id Z24O1NYO9AUCZB --vpc VPCRegion=ca-central-1,VPCId=vpc-0befb9df43910130c
```
``
**Output Result for Association**

```
This takes a while to change from `pending` to `Ready` stat:

    "ChangeInfo": {
        "Id": "/change/CP340ORULDRWG",
        "Status": "PENDING",
        "SubmittedAt": "2019-06-07T16:37:26.177Z",
        "Comment": ""
    }
}
```
<a name="SSL"></a>
#### 7. Importing SSL Certificate into ACM

The following SSL Certificates are located under the Bitbucket repository called `iwms-cfn`, link is [here:](https://bitbucket.corporate.ciglobe.net/projects/AWSI/repos/iwms-cfn/browse/TLS-certificates?at=refs%2Fheads%2Ffeature%2FAWSID-374) 

 `iwms.aws.ciglobe.net.cer` 
 This certificate file is used for all three IWMS environments (dev, uat, prod). This includes the subject alternatives names`ASN` with wildcards as listed below.

```btach
*.iwms.aws.ciglobe.net, *.dev.iwms.aws.ciglobe.net, *.test.iwms.aws.ciglobe.net, *.tst.iwms.aws.ciglobe.net, *.uat.iwms.aws.ciglobe.net, *.prd.iwms.aws.ciglobe.net, *.prod.iwms.aws.ciglobe.net
```

**SSL Certificate Sample Preview**

- SSL Certificate: `cernew.cer`
```shell
            -----BEGIN CERTIFICATE-----
            Base64-encoded certificate
            -----END CERTIFICATE-----
```

- Private Key: `Wildcard.iwms.aws.ciglobe.net.key`

```shell
            -----BEGIN CERTIFICATE-----
            Base64-encoded Private key
            -----END CERTIFICATE-----
```
- CA Bundle: `iwms-chain.cer`

The CA bundle certificate includes TLS certificate, Private Key and Intermediate root Certificate. You would need to put all three certificates into one .cer file.

```shell
            -----BEGIN CERTIFICATE-----
            Base64-encoded certificate
            -----END CERTIFICATE-----

            -----BEGIN CERTIFICATE-----
            Base64-encoded certificate
            -----END CERTIFICATE-----

            -----BEGIN CERTIFICATE-----
            Base64-encoded certificate
            -----END CERTIFICATE-----
```
- Expiration 

A new TLS certificate will need to be signed by the Certificate Authority before April 20, 2023 to avoid any intruption of the service. This applies to all IWMS environments (dev, uat and prod). A request needs to be send to the Change Management Team. 

    - Issued: April 30, 2019
    - Expired: April 29, 2023

The SSL certificate, CA bundle and private key must be PEM-encoded.

This CLI script was used to import the signed certificate into AWS Certificate Manager for IWMS Accounts.

```batch
aws acm import-certificate --certificate file://iwms.aws.ciglobe.net.cer 
--certificate-chain file://iwms-Chain.cer --private-key file://wildcard.iwms.aws.ciglobe.net.key
```
**Output Result**
```
{
    "CertificateArn": "arn:aws:acm:us-east-1:633969933150:certificate/6d9370f0-5c12-4b25-8b65-3d5af0f5a1e1"
}
```
**Verifying the Certificate**

    - Login to the respective account via AWS Console
    - Switch to AWS Certificate Manager service.
    - Verify the Status, should show `"Issued"` in green.       


 <a name="OnPrem"></a>
 ## 11. **On-Prem Tasks**

These tasks are performed in the On-Prem datacenter. **No scripts used for these task  

**1. Create Conditional DNS forwarders for the following:**

Conditional forwarders are DNS quiries that send the DNS requests for `aws.ciglbe.net domain` to the VPC DNS Endpoint addresss of the `CI Shared` VPC which is 1.0.0.0.2 (CIDR Block Address of the Shared VPC + 2)

DNS Conditional forwarders have been created on the Windows DNS server under `aws.ciglobe.net` zone for the following DNS hosted zone.

` Shared account` hosts the Windows DNS/Domain Controllers. 



**2. Create AD Groups for SAML Authentication.**

Following AD groups have been created in the `corporate.ciglobe.net` and configured in `ADFS` for SAML authentication. 

SSO Link: https://sso.ci.com/adfs/ls/idpinitiatedsignon.htm

***IWMS-DEV AD Groups***

```batch
    AWS-154576756847-ADFSAdmin
    AWS-154576756847-ADFSAdministrators
    AWS-154576756847-ADFSBilling
    AWS-154576756847-ADFSChangeManagement
    AWS-154576756847-ADFSDevelopers
    AWS-154576756847-ADFSOperations
    AWS-154576756847-ADFSSecurity
```

***IWMS-UAT AD Groups***
```batch

    AWS-797026961867-ADFSAdmin
    AWS-797026961867-ADFSAdministrators
    AWS-797026961867-ADFSBilling
    AWS-797026961867-ADFSChangeManagement
    AWS-797026961867-ADFSDevelopers
    AWS-797026961867-ADFSOperations
    AWS-797026961867-ADFSQA
    AWS-797026961867-ADFSSecurity
```
***IWMS-PROD AD Groups***
```batch

    AWS-633969933150-ADFSAdmin
    AWS-633969933150-ADFSAdministrators
    AWS-633969933150-ADFSBilling
    AWS-633969933150-ADFSChangeManagement
    AWS-633969933150-ADFSDevelopers
    AWS-633969933150-ADFSOperations
    AWS-633969933150-ADFSQA
    AWS-633969933150-ADFSSecurity
```
**3. Following mailboxes have been created on the CI Excange Server**

```batch
    aws_iwms_devel@ci.com
    aws_iwms_uat@ci.com
    aws_iwms_prod@ci.com
```
    
**4. SSL/TLS Certificates for IWMS Accounts.**

TLS/SSL are signed by the Certificate authority managed by `Change Management` team, and then imported into `AWS Certificate Manager`.

Importing SSL certificate into AWS Certificate Manager, please refer to `Step-8` above.

**5. Add VPC CIDR Block Addresses to Active Directory Sites and Services.**
   The CIDR block addresses need to be added to the AD in order for LDAP to work from AWS VPCs.

   #### USAGE:

   1. Launch AD `Sites and Services` console from the `CIGLOBE.NET` domain.
   2. Under the `subnet` section, create new subnets and add the following CIDR addresses of the VPCs.
   
      
   
<a name="InfoSec"></a>
 ## 12. **Security Requirements**

**1. Deploy `ci-benchmark` template**

This template deploys the Security Benchmark with the nested stackes to configure the `AWS Config`, `Cloud Trail` and `Cloud Watch`.

AWS Cli Script to execute this template:
```batch
aws cloudformation create-stack --template-body file://ci-benchmark.yaml --parameters file://ci-benchmarkParameters.json --stack-name ci-benchmark --capabilities CAPABILITY_NAMED_IAM
```

**2.  Move the accounts to `CI Investments` Organization.**
     
A custom Organization policy has been created and configured as per the Security standard called `CI Investments`.

   - Login to the `Master account`, move the new account to `CI-Investments` organization. 

**3. Remove the Default VPCs from all regions.**

As per the Security Requirements, default VPC need to be removed from all regions.

   - Use the `removedefaultvpc.sh` script from the toolbox instance to remove all VPCs from all the regions.

**4. Apply the IAM password policy.**
   - From the IAM console, set the password policy according to Security Requirements.

**5. Cleanup any IAM user(s) that were created during the project.**

-----------

