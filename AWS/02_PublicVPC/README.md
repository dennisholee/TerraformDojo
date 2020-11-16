export AWS_ACCESS_KEY_ID=(your access key id)
export AWS_SECRET_ACCESS_KEY=(your secret access key)


eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
ssh -A v.x.y.z


SSH User Accounts
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/managing-users.html

> For Amazon Linux 2 or the Amazon Linux AMI, the user name is ec2-user.
> For a CentOS AMI, the user name is centos.
> For a Debian AMI, the user name is admin.
> For a Fedora AMI, the user name is ec2-user or fedora.
> For a RHEL AMI, the user name is ec2-user or root.
> For a SUSE AMI, the user name is ec2-user or root.
> For an Ubuntu AMI, the user name is ubuntu.
> Otherwise, if ec2-user and root don't work, check with the AMI provider.


ssh ec2-user@v.x.y.z
