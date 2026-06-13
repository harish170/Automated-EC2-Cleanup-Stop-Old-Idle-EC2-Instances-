# AWS EC2 Cleanup Automation

Python automation to stop old EC2 instances.

## Features

- Stops EC2 older than 30 days
- Excludes tagged instances
- Lambda compatible
- EventBridge scheduler
- Terraform deployment

## Run locally

pip install -r requirements.txt

python app.py


## Deploy

terraform init

terraform apply
