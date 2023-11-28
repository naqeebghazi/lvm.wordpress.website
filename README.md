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

## Part 1: Create a Webserver EC2 instance using a RedHat image (free tier) and ensure you attach 3 gp2/gp3 EBS volumes to the instance. 

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

    $ sudo lvcreate -n db-lv -L 14G webdata-vg
    $ sudo lvcreate -n logs-lv -L 14G webdata-vg

![lvcreate](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lvcreate_apps.logs.png?raw=true)

Validate entire setup:

    $ sudo vgdisplay -v #view complete setup - VG, PV, LV
    $ sudo lsblk

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vgdisplay.png?raw=true)

&

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/lsblk_2.png?raw=true)

Format the new logical volumes you created with the ext4 filesystem:

    $ sudo mkfs -t ext4 /dev/webdata-vg/apps-lv
    $ sudo mkfs -t ext4 /dev/webdata-vg/logs-lv

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/mkfs_ext4.png?raw=true)

## Part 2: Setting up your logical volumes as part of a webserver

Create /var/www/html directory to store website files

    $ sudo mkdir -p /var/www/html

Create /home/recovery/logs to store backup of log data:

    $ sudo mkdir -p /home/recovery/logs

Mount the html directory on the apps-lv logical volume:

    $ sudo mount /dev/webdata-vg/apps-lv /var/www/html/

Backup all the files in the /var/log directory into the /home/recovery/logs

    $ sudo rsync -av /var/log/. /home/recovery/logs

Mount the /var/log directory on the log-lv logivcal volume. 

    $ sudo mount /dev/webdata-vg/logs-lv /var/log

Restore log files back into /var/log directory:

    $ sudo rsync -av /home/recovery/logs/log/. /var/log

Update /etc/fstab. This persists the mount configuration even after restart. 

    $ sudo blkid 

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/sudoblkid.png?raw=true)

These two sections from the above command are important. Take the UUIDs and copy to clipboard as instructued below. 
/dev/mapper/webdata--vg-logs--lv: UUID="b33c1c1b-7cdf-4554-81fd-ca9ba25ddf17" TYPE="ext4"
/dev/mapper/webdata--vg-apps--lv: UUID="d8722a79-579c-4e7f-8e36-c57092c746c3" TYPE="ext4"

Edit /etc/fstab and replace the UUID in it with the UUIDs of the /dev/mapper/ UUIDs (removing the quotation marks):

    $ sudo vi /etc/fstab

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vifstab.png?raw=true)

Ensure formatting is the same as above, especially the columns next to the UUIDs. 
Save the file with :wq!

Test new configuration and reload the file:

    $ sudo mount -a
    $ sudo systemctl daemon-reload

Validate setup

    $ df -h

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/daemon-reload.png?raw=true)

###################################################################################################################################################################################################

## Part 3: Installing Wrodpress and MySQL configuration

### Preapring the database server

Create a new EC2 instance for the Dayabase server by following all the same steps as above, with the following difference:

    Instead of apps-lv, make db-lv and mount it to /db instead of /var/www/html

All steps repeated below but for the database:

SH into the instance and update the system:

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


Use vgcreate utility to add all 3 PVs to a volume group (vg) called dbdata-vg:

    $ sudo vgcreate dbdata-vg /dev/xvdb1 /dev/xvdc1 /dev/xvdd1

  Then verify the above:

      $ sudo vgs

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/vg-create.png?raw=true)

The lvcreate command is part of the Logical Volume Manager (LVM) system in Linux. It is used to create logical volumes within a volume group. Logical volumes are similar to partitions in traditional disk partitioning schemes but offer more flexibility and features. 

Use lvcreate to make to logical volumes from the dbdata-vg volume group:

    $ sudo lvcreate -n db-lv -L 14G dbdata-vg
    $ sudo lvcreate -n logs-lv -L 14G dbdata-vg

Validate with lvs which lists the logical volumes

    $ sudo lvs

![lvcreate](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/db_lvs.png?raw=true)

Validate entire setup:

    $ sudo vgdisplay -v #view complete setup - VG, PV, LV
    $ sudo lsblk

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/db-validateALL.png?raw=true)

&

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/db_lsblk.png?raw=true)

Format the new logical volumes you created with the ext4 filesystem:

    $ sudo mkfs -t ext4 /dev/dbdata-vg/db-lv
    $ sudo mkfs -t ext4 /dev/dbdata-vg/logs-lv

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/dbdata_format_ext4.png?raw=true)

## Part 2: Setting up your logical volumes as part of a webserver

Create /var/www/html directory to store website files

    $ sudo mkdir -p /db

Create /home/recovery/logs to store backup of log data:

    $ sudo mkdir -p /home/recovery/logs

Mount the html directory on the db-lv logical volume:

    $ sudo mount /dev/dbdata-vg/db-lv /db

Backup all the files in the /var/log directory into the /home/recovery/logs

    $ sudo rsync -av /var/log/. /home/recovery/logs

Mount the /var/log directory on the log-lv logivcal volume. 

    $ sudo mount /dev/dbdata-vg/logs-lv /var/log

Restore log files back into /var/log directory:

    $ sudo rsync -av /home/recovery/logs/log/. /var/log

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/sudoRsync_forDB.png?raw=true)

Update /etc/fstab. This persists the mount configuration even after restart. 

    $ sudo blkid 

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/sudoblkid.png?raw=true)

These two sections from the above command are important. Take the UUIDs and copy to clipboard as instructued below. 
/dev/mapper/dbdata--vg-logs--lv: UUID="b33c1c1b-7cdf-4554-81fd-ca9ba25ddf17" TYPE="ext4"
/dev/mapper/dbdata--vg-apps--lv: UUID="d8722a79-579c-4e7f-8e36-c57092c746c3" TYPE="ext4"

Edit /etc/fstab and replace the UUID in it with the UUIDs of the /dev/mapper/ UUIDs (removing the quotation marks):

    $ sudo vi /etc/fstab

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/database-fstab.png?raw=true)

Ensure formatting is the same as above, especially the columns next to the UUIDs. 
Save the file with :wq!

Test new configuration and reload the file:

    $ sudo mount -a
    $ sudo systemctl daemon-reload

Validate setup

    $ df -h

![](https://github.com/naqeebghazi/lvm.wordpress.website/blob/main/images/df-h_db.png?raw=true)

