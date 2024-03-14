Before you run any scripts create an SSH with the following command:
ssh-keygen -t 25519 -f ~/.ssh/ed25519
Copy the ssh key to root and regular user:
ssh-copy-id -i ~/.ssh/ed25519 root@localhost
ssh-copy-id -i ~/.ssh/ed25519 localhost
