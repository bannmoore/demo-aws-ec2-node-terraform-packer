# Demo - AWS, Node, Packer, and Terraform

## AWS Credentials

In order to use this repository, you'll need an AWS account (free tier is sufficient) and an AWS access key id and secret key.

These values need to be loaded as environment variables when you run the commands below.

```sh
export AWS_ACCESS_KEY_ID=my-key-id
export AWS_SECRET_ACCESS_KEY=my-secret-access-key
```

### AWS Permissions

Your AWS user needs to have certain permissions in order to use Packer and Terraform. The policies `AdministratorAccess` and `AmazonEC2FullAccess` will probably do the job, but aren't ideal for a production application.

If you're interested in creating more granular users or groups for Terraform and Packer, these are the individual permissions you'll need.

```json
{
    "Statement": [
        {
            "Sid": "Packer",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeImages",
                "ec2:RegisterImage",
                "ec2:CreateImage",
                "ec2:RebootInstances",
                "ec2:TerminateInstances",
                "ec2:StartInstances",
                "ec2:CreateTags",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:DescribeInstances",
                "ec2:CreateKeyPair",
                "ec2:DescribeKeyPairs",
                "ec2:DeleteKeyPair",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Terraform",
            "Effect": "Allow",
            "Action": [
                "ec2:RevokeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CreateSecurityGroup",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeImages",
                "ec2:RegisterImage",
                "ec2:CreateImage",
                "ec2:RebootInstances",
                "ec2:DescribeInstances",
                "ec2:TerminateInstances",
                "ec2:DescribeTags",
                "ec2:CreateTags",
                "ec2:DescribeInstanceAttribute",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:DescribeInstanceCreditSpecifications",
                "ec2:GetPasswordData",
                "ec2:StartInstances",
                "ec2:DescribeVpcs",
                "ec2:DescribeVolumes",
                "ec2:ModifyInstanceAttribute",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateKeyPair",
                "ec2:DescribeKeyPairs",
                "ec2:DeleteKeyPair"
            ],
            "Resource": "*"
        }
    ]
}
```

## Run the Application Locally

```sh
cd app
npm install
npm start
```

The application is simple, with only one endpoint.

```
$ curl localhost:8080
Hello, World
```

## Packer: Instance Image

Next, we're going to create an immutable infrastructure. Instead of using a basic AMI and running a script after start-up that installs our app, we'll use Packer to preinstall all those things and then deploy that image.

```sh
cd packer
packer build config.json
```

Once this script completes, Packer will output the new AMI's id.

```
==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
us-east-1: ami-000000
```

Note: This process creates an AMI and a snapshot on your AWS account. Storing these over time can accumulate charges, so you'll need to manage them yourself. You can get rid of an AMI by deregistering it and deleting its associated snapshot on the EC2 Dashboard.

## Terraform: Deploy Infrastructure

### Update AMI

First, open `terraform/vars.tf` and update the `ami` default value with the AMI id created by packer.

```
variable "ami" {
  description = "The AMI used by the ec2 instance"
  default     = "ami-000000" # update this value with the ami created by packer
}
```

### Add Public Key (optional)

If you want to `ssh` into your ec2 instance, you have to add a key pair resource. To do so in this repo:

1. In `terraform/keys.tf`, uncomment the `aws_key_pair` resource and paste your public key into the `public_key` field.
2. In `terraform/vars.tf`, update the `key_pair_name` default value to match the key pair's `key_name` (`deployer-key`).

This Terraform infrastructure will still work if you skip these steps, but you won't be able to use `ssh`.

### Deploy

```sh
cd terraform
terraform init # first time only
terraform apply
```

If the commands complete successfully, you'll see the public DNS and public IP address outputted in the console.

```
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

public_dns = ec2-54-83-167-190.compute-1.amazonaws.com
public_ip = 54.83.167.190
```

Use these to validate the Node app. **NOTE**: the container may take several minutes to initialize; the endpoint will return `Connection refused` during that time. Check the EC2 Dashboard - when you see "2/2 checks" under the Status Checks column, the instance endpoints should be available.

```
$ curl ec2-54-83-167-190.compute-1.amazonaws.com:8080
Hello, World
```

If you configured Terraform with a public key (see instructions above), you can also access the instance via SSH.

```
$ ssh -i ~/.ssh/id_rsa.aws ec2-user@ec2-54-83-167-190.compute-1.amazonaws.com

       __|  __|_  )
       _|  (     /   Amazon Linux AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-ami/2018.03-release-notes/
[ec2-user@ip-172-31-46-185 ~]$
```

### Teardown

If you're just using this repo for practice on a free-tier account, make sure you teardown the infrastructure using `terraform destroy`.

```
$ terraform destroy
aws_key_pair.deployer: Refreshing state... (ID: deployer-key)
aws_security_group.instance: Refreshing state... (ID: sg-0df07e423545801b8)
aws_security_group.ssh: Refreshing state... (ID: sg-0ee5473d6a4ad8c2e)
aws_instance.bam: Refreshing state... (ID: i-063acc7adaa5542b7)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  - aws_instance.bam

  - aws_key_pair.deployer

  - aws_security_group.instance

  - aws_security_group.ssh


Plan: 0 to add, 0 to change, 4 to destroy.

Do you really want to destroy?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_key_pair.deployer: Destroying... (ID: deployer-key)
aws_instance.bam: Destroying... (ID: i-063acc7adaa5542b7)
aws_key_pair.deployer: Destruction complete after 1s
aws_instance.bam: Still destroying... (ID: i-063acc7adaa5542b7, 10s elapsed)
aws_instance.bam: Still destroying... (ID: i-063acc7adaa5542b7, 20s elapsed)
aws_instance.bam: Still destroying... (ID: i-063acc7adaa5542b7, 30s elapsed)
aws_instance.bam: Still destroying... (ID: i-063acc7adaa5542b7, 40s elapsed)
aws_instance.bam: Still destroying... (ID: i-063acc7adaa5542b7, 50s elapsed)
aws_instance.bam: Still destroying... (ID: i-063acc7adaa5542b7, 1m0s elapsed)
aws_instance.bam: Destruction complete after 1m1s
aws_security_group.ssh: Destroying... (ID: sg-0ee5473d6a4ad8c2e)
aws_security_group.instance: Destroying... (ID: sg-0df07e423545801b8)
aws_security_group.instance: Destruction complete after 1s
aws_security_group.ssh: Destruction complete after 1s

Destroy complete! Resources: 4 destroyed.
```

### Debug

To enable logging on Terraform commands, set the `TF_LOG` environment variable before execution. `TRACE` is the highest level of logging.

```sh
TF_LOG=TRACE terraform plan
```

If your error is authorization-related, you'll receive an "encoded authorization failure message". Here's an example of one I received while looking for minimal permissions:

```
* aws_instance.bam: Error launching source instance: UnauthorizedOperation: You are not authorized to perform this operation. Encoded authorization failure message: VZe33_jbYatLPoufuIj6-yREVQFDg7oWJeZdd9P6vgI3ZKTuvWLORet5HCC0-SHoeQcoRzAxOmw_1lAawVYJHGttxv2x93-gWIZALDpNg8x_MDoodhnNDTWPNYm7-dSaa-iJuwm_xK-C-pPZcLZdQx4OIG4KWb3t3XU7hMhCw0uyBQ8iyN-QHaONqWcPMeQ86j2Q7sd1pdRmdYSiBEsoZEH_3i8J-2UbChTyos4gkxJJbgz9NQ_is0awo5QSc6N9wt1R7-wsLixXTzYpbAPKKlYHGxCe8AgsMccjDxqr8QdLoH9a5Q8TQXLM3u6RtI49qEnseIXrRsietr8zZRl9xu7DvBhnPlUCGJ9QMw8hfFVlDkv_1VkDVdSZ7_KeLEdlz4mfrw0uYbWqfJ3wsl-EONfgAApVQ-OoWZwNaqY0ZYpdnjKr1Vu3xsJZPx_hco_r1isy7ubcBMeaiYNA3XQRN6dK8Rg1H4ufHu9w_ROaEu_iXDycNRi26GzdPsNrdM5nTRHOuxSzPmSjz0nKsI4AqNcqellzfeCGTYOXsda9x-pMSR74m3VH8ESE8VdYVqS9PgqbqeLlL9MoPp1XPRuBNRe2p-H4JAbLqU8xkdYQS9fLIII8Lbd2hGnANodKbWA1ImuNUeBOjM9Uo_AfB7cfRQ0ehZAFeMo4vdBlFfbVSjQ
```

To decode this message, you can use the AWS CLI (this requires a user with the permission `sts:DecodeAuthorizationMessage`).

```
$ aws sts decode-authorization-message --encoded-message VZe33_jbYatLPoufuIj6-yREVQFDg7oWJeZdd9P6vgI3ZKTuvWLORet5HCC0-SHoeQcoRzAxOmw_1lAawVYJHGttxv2x93-gWIZALDpNg8x_MDoodhnNDTWPNYm7-dSaa-iJuwm_xK-C-pPZcLZdQx4OIG4KWb3t3XU7hMhCw0uyBQ8iyN-QHaONqWcPMeQ86j2Q7sd1pdRmdYSiBEsoZEH_3i8J-2UbChTyos4gkxJJbgz9NQ_is0awo5QSc6N9wt1R7-wsLixXTzYpbAPKKlYHGxCe8AgsMccjDxqr8QdLoH9a5Q8TQXLM3u6RtI49qEnseIXrRsietr8zZRl9xu7DvBhnPlUCGJ9QMw8hfFVlDkv_1VkDVdSZ7_KeLEdlz4mfrw0uYbWqfJ3wsl-EONfgAApVQ-OoWZwNaqY0ZYpdnjKr1Vu3xsJZPx_hco_r1isy7ubcBMeaiYNA3XQRN6dK8Rg1H4ufHu9w_ROaEu_iXDycNRi26GzdPsNrdM5nTRHOuxSzPmSjz0nKsI4AqNcqellzfeCGTYOXsda9x-pMSR74m3VH8ESE8VdYVqS9PgqbqeLlL9MoPp1XPRuBNRe2p-H4JAbLqU8xkdYQS9fLIII8Lbd2hGnANodKbWA1ImuNUeBOjM9Uo_AfB7cfRQ0ehZAFeMo4vdBlFfbVSjQ
{
    "DecodedMessage": "{\"allowed\":false,\"explicitDeny\":false,\"matchedStatements\":{\"items\":[]},\"failures\":{\"items\":[]},\"context\":{\"principal\":{\"id\":\"AIDAIGYYT2MT7SO5TEQRM\",\"name\":\"happy-go-lucky\",\"arn\":\"arn:aws:iam::010759401675:user/happy-go-lucky\"},\"action\":\"ec2:CreateTags\",\"resource\":\"arn:aws:ec2:us-east-1:010759401675:instance/*\",\"conditions\":{\"items\":[{\"key\":\"ec2:InstanceMarketType\",\"values\":{\"items\":[{\"value\":\"on-demand\"}]}},{\"key\":\"aws:Resource\",\"values\":{\"items\":[{\"value\":\"instance/*\"}]}},{\"key\":\"aws:Account\",\"values\":{\"items\":[{\"value\":\"010759401675\"}]}},{\"key\":\"ec2:AvailabilityZone\",\"values\":{\"items\":[{\"value\":\"us-east-1b\"}]}},{\"key\":\"ec2:ebsOptimized\",\"values\":{\"items\":[{\"value\":\"false\"}]}},{\"key\":\"ec2:IsLaunchTemplateResource\",\"values\":{\"items\":[{\"value\":\"false\"}]}},{\"key\":\"ec2:InstanceType\",\"values\":{\"items\":[{\"value\":\"t2.micro\"}]}},{\"key\":\"ec2:RootDeviceType\",\"values\":{\"items\":[{\"value\":\"ebs\"}]}},{\"key\":\"aws:Region\",\"values\":{\"items\":[{\"value\":\"us-east-1\"}]}},{\"key\":\"aws:Service\",\"values\":{\"items\":[{\"value\":\"ec2\"}]}},{\"key\":\"ec2:InstanceID\",\"values\":{\"items\":[{\"value\":\"*\"}]}},{\"key\":\"aws:Type\",\"values\":{\"items\":[{\"value\":\"instance\"}]}},{\"key\":\"ec2:Tenancy\",\"values\":{\"items\":[{\"value\":\"default\"}]}},{\"key\":\"ec2:Region\",\"values\":{\"items\":[{\"value\":\"us-east-1\"}]}},{\"key\":\"aws:ARN\",\"values\":{\"items\":[{\"value\":\"arn:aws:ec2:us-east-1:010759401675:instance/*\"}]}}]}}}"
}
```

Because it's an authorization issue, we want to hone in on the `action` in the decoded message: `\"action\":\"ec2:CreateTags\"`. To fix this error, I added `ec2:CreateTags` to my Terraform user.

Resources:
- [How to Decode Authorization Message]http://cloudway.io/post/decode-authorization-message/
- [Debugging Terraform] - https://www.terraform.io/docs/internals/debugging.html