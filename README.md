        __  __ _____ ____
       |  \/  |_   _|  _ \
       | |\/| | | | | |_) |
       | |  | | | | |  __/
       |_|  |_| |_| |_|

      Mass Testing Platform


#### Introduction

This is a set of Terraform code that will bring up a fully functional MTP site with the following requirements:

- Public website behind a public load balancer.
- Application instance + database in a private network.
- At least 2 instances of the application configured with autoscaling.

MTP is a sample application located here: https://github.com/QuickenLoans/MassTestingPlatform

#### Setup

You need to have the following tools installed and operational:

- `make`
- `awscli`
- `terraform >= v12.28`
- `jq`

If you're on a Mac running Homebrew, you can install these dependencies by running `brew bundle` in this directory.

#### Configuration

This code is driven by a `Makefile` with the following targets:

- `init`: sets up the Terraform state bucket and DynamoDB lock table required for the deployment.
- `plan`: runs a Terraform `plan` command to show what Terraform would do if `apply` were run.
- `apply`: runs a Terraform `apply` to deploy the changes.
- `destroy`: removes everything that Terraform has deployed.

This code only runs in AWS and requires a configured `~/.aws/credentials` file with a profile specified as `AWS_PROFILE` and a region specified as `AWS_REGION`.

Settings are driven by an environment file located in the `environments` folder. Each .tfvars file has to be named as `{product}-{environment}.tfvars` (eg. mtp-production.tfvars). Each invocation of Make will try to locate an appropriate environment file based on the values of the environment variables `PRODUCT` and `ENVIRONMENT`.

The complete list of variables which can be overridden are in the file `variables.tf`. If they're not overridden in the `.tfvars` file, then the default specified in `variables.tf` will be used.

You'll need to override the `public_route53_zone` variable to point at a Route53 domain within your account. You'll also need to create a Key Pair and specify the name of the keypair in the `key_name` variable. Make both of these changes in the `environments/mtp-production.tfvars`.

This code will create an A record alias at the apex of your domain, so it's best to use an unused domain.

#### Deploying

Start by setting the `PRODUCT` environment variable to `mtp` and the `ENVIRONMENT` variable to `production`. Also, make sure your `AWS_PROFILE` and `AWS_REGION` environment variables are set properly. Your `AWS_PROFILE` variable should point at a profile in `~/.aws/credentials` with sufficient IAM permissions to build out all of the required infrastructure.

```bash
export AWS_PROFILE=default
export AWS_REGION=us-west-2
export PRODUCT=mtp
export ENVIRONMENT=production
```

Next, run `make init`. This will create a new encrypted, versioned S3 bucket to hold Terraform state. It will also create a new DynamoDB table for Terraform statefile locking. This will prevent 2 users from running an `apply` at the same time.

Last, run `make apply`. If you're starting from scratch, this will deploy everything and within 10 minutes, you'll be able to navigate to either `www.{your domain}` or `{your domain}`. If you connect via HTTP, you'll be automatically redirected to HTTPS. The adminer tool will also be available at `adminer.{your domain}`

From here, you can configure Easy!Appointments.

A bastion instance will be brought up at `bastion.{your domain}` that you can use to connect to the hosts in your environment if you need to troubleshoot. The username is `ubuntu` and the key will be the key specified in the `key_name` variable.

__NOTE__: By default, only the IP of the machine running Terraform will have SSH access to the bastion instance.

Once you're done, you can tear everything down with `make destroy`. This will not remove the Terraform state S3 bucket or the DynamoDB table.

#### Notes

Running this in us-east-1 runs the risk of constantly recreating the ACM certificate due to a bug: https://github.com/terraform-providers/terraform-provider-aws/issues/8531

ACM certs also appear to take much longer to validate in us-east-1, which can cause Terraform to timeout. The Oregon region (us-west-2) has been flawless.
