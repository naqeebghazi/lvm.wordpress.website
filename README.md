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

Install lvm:

    $ sudo yum install lvm2

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvm2install.png?raw=true)

Lvm helps us to manage the disks. Run LVM disk scan:

    $ sudo pvcreate /dev/xvdb

Output:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvmdiskscan.png?raw=true)

The pvcreate command in LVM (Logical Volume Manager) is used to initialize a physical volume, preparing it for use in an LVM volume group. When you add a new hard disk or a partition to an LVM setup, you need to run pvcreate on that device to make it available for use in LVM. 
Run pvcreate on each disk:

    $ sudo pvcreate /dev/xvdb1
    $ sudo pvcreate /dev/xvdc1
    $ sudo pvcreate /dev/xvdd1

This creates physical volumes with a new name = original disk name + number (e.g. xvda -> xvda1 

Then verfiy the above commands worked by running:

    $ sudo pvs

Result of above:

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/pvcreate.png?raw=true)


Use vgcreate utility to add all 3 PVs to a volume group (vg) called webdata-vg:

    $ sudo vgcreate webdata-vg /dev/xvdb1 /dev/xvdc1 /dev/xvdd1

  Then verify the above:

      $ sudo vgs

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vg-create.png?raw=true)

The lvcreate command is part of the Logical Volume Manager (LVM) system in Linux. It is used to create logical volumes within a volume group. Logical volumes are similar to partitions in traditional disk partitioning schemes but offer more flexibility and features. 

Use lvcreate to make to logical volumes from the webdata-vg volume group:

    $ sudo lvcreate -n apps-lv -L 14G webdata-vg
    $ sudo lvcreate -n logs-lv -L 14G webdata-vg

![lvcreate](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvcreate_apps.logs.png?raw=true)

Validate entire setup:

    $ sudo vgdisplay -v #view complete setup - VG, PV, LV
    $ sudo lsblk

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vgdisplay.png?raw=true)

&

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblk_2.png?raw=true)






  Format Partitions:
  After partitioning, you need to format the partitions using a filesystem of your choice. For example, to format a partition with ext4:
  
  bash
  Copy code
  sudo mkfs.ext4 /dev/sdXn
  Replace /dev/sdXn with the actual partition identifier.
  
  Remember to be cautious when using partitioning tools, as they can result in data loss if not used correctly. Make sure you have a backup of important data before making any changes to disk partitions.
