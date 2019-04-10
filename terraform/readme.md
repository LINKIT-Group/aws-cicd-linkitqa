# Get all recources in destroy.plan but exclude aws_codecommit_repository items
terraform plan -destroy $(for r in `terraform state list | fgrep -v aws_codecommit_repository` ; do echo "-target ${r} "; done) -out destroy.plan

# After that use following command to exectue destroy plan
terraform apply "destroy.plan"
