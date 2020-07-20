ACCOUNT_ID=$(shell aws sts get-caller-identity | jq -r '.Account')
BUCKET_NAME=$(PRODUCT)-$(ENVIRONMENT)-$(ACCOUNT_ID)-$(AWS_REGION)-terraform

init:
	@echo Creating bucket for Terraform state storage
	if [ $(AWS_REGION) = 'us-east-1' ]; then \
		aws s3api create-bucket --bucket $(BUCKET_NAME) --profile $(AWS_PROFILE) --region $(AWS_REGION) || exit 0; \
	else \
		aws s3api create-bucket --bucket $(BUCKET_NAME) --profile $(AWS_PROFILE) --region $(AWS_REGION) --create-bucket-configuration LocationConstraint=$(AWS_REGION) || exit 0; \
	fi
	aws s3api put-bucket-versioning --bucket $(BUCKET_NAME) --profile $(AWS_PROFILE) --region $(AWS_REGION) --versioning-configuration Status=Enabled || exit 0
	aws s3api put-bucket-encryption --bucket $(BUCKET_NAME) --profile $(AWS_PROFILE) \
		--region $(AWS_REGION) --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}' || exit 0
	aws s3api put-public-access-block --bucket $(BUCKET_NAME) --profile $(AWS_PROFILE) \
		--region $(AWS_REGION) --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" || exit 0

	@echo Creating DynamoDB table for Terraform locks
	aws dynamodb create-table --profile $(AWS_PROFILE) --region $(AWS_REGION) --table-name $(BUCKET_NAME) \
		--attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH \
		--provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 || exit 0

	@echo Ready to rock!

clean:
	@rm -rf .terraform

config:
	@terraform fmt
	@terraform init -backend=true -backend-config="bucket=$(BUCKET_NAME)" -backend-config="key=application.tfstate" \
								  -backend-config="region=$(AWS_REGION)" -backend-config="dynamodb_table=$(BUCKET_NAME)" -get=true \
								  -backend-config="profile=$(AWS_PROFILE)" -get-plugins=true -verify-plugins=true

plan: config
	@echo Running Terraform plan for $(PRODUCT) $(ENVIRONMENT)
	@terraform plan -var aws_profile=$(AWS_PROFILE) -var aws_region=$(AWS_REGION) -var-file=environments/$(PRODUCT)-$(ENVIRONMENT).tfvars

apply: config
	@echo Applying Terraform changes for $(PRODUCT) $(ENVIRONMENT)
	@terraform apply -var aws_profile=$(AWS_PROFILE) -var aws_region=$(AWS_REGION) -var-file=environments/$(PRODUCT)-$(ENVIRONMENT).tfvars

destroy: config
	@echo Destroying $(PRODUCT) $(ENVIRONMENT)
	@terraform destroy -var aws_profile=$(AWS_PROFILE) -var aws_region=$(AWS_REGION) -var-file=environments/$(PRODUCT)-$(ENVIRONMENT).tfvars

console: config
	@echo Launching Terraform REPL for $(PRODUCT) $(ENVIRONMENT)
	@terraform console -var aws_profile=$(AWS_PROFILE) -var aws_region=$(AWS_REGION) -var-file=environments/$(PRODUCT)-$(ENVIRONMENT).tfvars
