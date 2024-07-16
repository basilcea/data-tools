
#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 /path/to/local/directory/ /path/to/remote/directory/"
  exit 1
fi

# Assign command-line arguments to variables
LOCAL_DIR=$1
REMOTE_DIR=$2

# Configuration
REMOTE_USER="ec2-user"
REMOTE_HOST="ec2-44-239-192-140.us-west-2.compute.amazonaws.com"
SSH_KEY="~/.ssh/EC2-demo.pem"

# Rsync command
rsync -avz -e "ssh -i $SSH_KEY" "$LOCAL_DIR" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

# Check for success
if [ $? -eq 0 ]; then
  echo "Sync completed successfully."
else
  echo "Error during sync."
fi