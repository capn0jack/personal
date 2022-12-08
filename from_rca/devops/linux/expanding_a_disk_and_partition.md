## Expanding a disk and partition on an EC2 instance (NVMe).  See https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html

Resize the EBS volume.

SSH into the instance and list the block devices:

        lsblk

Grow the partition:

        sudo growpart /dev/nvme0n1 1

Check that it worked:

        lsblk

Extend the filesystem:

        sudo resize2fs /dev/nvme0n1p1