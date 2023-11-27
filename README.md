# lvm.wordpress.website

Implementing WordPress Website with LVM Storage Management on AWS EC2 Ubuntu

A typical 3-tier architecture (3TA) consists of:
- Presentation tier: What you see and interact with in your web browser or application (e.g. via a personal laptop, phone, tablet)
- Application tier: Backend of the application/website that processes all the input/outputs and any other computational requirements
- Data tier: Data storage and data access. Database server e.g. FTP server and NFS server

Simplified outline of a 3TA:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/gen3tierarchitecture.png?raw=true)

Example outline of a 3TA in AWS:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/aws3tierarchitecture.png?raw=true)

We will be focusing on the Application and Data tiers as thats where our DevOps skills are more emphasised. The presentation tier is more web design focused. 
So, our project will be to:
  1. Data tier: Setup of storage for both Web and Database servers
  2. Application tier: WordPress installation onto a Webserver which is connected to a seperate MySQL database server

Create a Webserver EC2 instance using a RedHat image (free tier) and ensure you attach 3 gp2/gp3 EBS volumes to the instance. 
SSH into the instance and update the system:

    $ sudo yum update

Check that volumes are attached:

    $ lsblk 

![lsblk](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblk.png?raw=true)

The volumes you added are xvdb, xvdc, xvdd. These corresspond to Vol1, Vol2 and Vol3 respectiively in the AWS console:

![Vol123](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/Vol123.png?raw=true)

To see all the mounted volumes and free space on your server:

    $ df -h

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/df-h.png?raw=true)

Use gdisk to create a single partition on each of the 3 disks:

    $ sudo gdisk /dev/xvdb
    $ sudo gdisk /dev/xvdc
    $ sudo gdisk /dev/xvdd

  After each gdisk command above, follow these steps:
  Once inside gdisk, you can create partitions using the following steps:
  
  - Press n to create a new partition.
  - Choose the partition number.
  - Set the starting sector and ending sector for the partition. If you want to use the entire disk, you can press Enter to accept the default values.
  - Choose the partition type. You can press Enter to accept the default if you're unsure.
  - Optionally, you can set a name for the partition.
  - Repeat these steps to create additional partitions if needed.

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/df-h.png?raw=true)
  
  Review Changes:
  After creating partitions, use the p command to review the changes.
  
  Write Changes to Disk:
  If you're satisfied with the changes, press Y to write the changes to the disk.

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/wY.png?raw=true)

Check Partition with lsblk command:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblkcheckPartition.png?raw=true)

Install lvm

    $ sudo yum install lvm2

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvm2install.png?raw=true)

  Format Partitions:
  After partitioning, you need to format the partitions using a filesystem of your choice. For example, to format a partition with ext4:
  
  bash
  Copy code
  sudo mkfs.ext4 /dev/sdXn
  Replace /dev/sdXn with the actual partition identifier.
  
  Remember to be cautious when using partitioning tools, as they can result in data loss if not used correctly. Make sure you have a backup of important data before making any changes to disk partitions.
