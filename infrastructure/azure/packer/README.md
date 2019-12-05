# Build Azure Images using Packer commands
1. packer --version
2. packer validate -var-file=<local-var-file-name> centos-image.json
3. packer build -var-file=<local-var-file-name> centos-image.json

### Once you run packer commands your AMI is created, check the UI and verify with the AMI id in the terminal
