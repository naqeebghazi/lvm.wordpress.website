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

