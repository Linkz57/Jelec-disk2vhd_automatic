So, this is a pretty neat project, if I do say so myself.    
Disk2VHD is a fantastic program written by the great Mark Russinovich of Sysinternals, now owned by Microsoft. Like many great tools, it does one thing very well. In this case, that's taking a live disk and sticking it in a VHD file. It does not clean up after itself, it is not conducive to automation or scheduling backups of machines running Windows newer than 2003 and it doesn't notify the user of successes or failures--it doesn't even keep logs. All of these are things I wanted, so I added them myself. Enter disk2vhd_automatic.bat which aims to do all of that, except the cleaning which is handled by disk2vhd_clanup.sh.

# disk2vhd_automatic.bat
This script is designed to aid a phase in automating a cheap backup system that will perform live, bare-metal backups that are then able to be quickly virtualized at a moment's notice. This script is scheduled to run locally by each of the servers we want to be backed up.


# disk2vhd_cleanup.sh
This script is designed to cleanup the constant influx of VHD files created by disk2vhd_automatic.bat. It does this by deleting all but the newest 4 or so files for each server. This script is scheduled to run on a single server, and clean up each VHD repository created by each server running the disk2vhd_automatic.bat script.


# Why bother
disk2vhd_automatic is only part of the puzzle. The goal of all of this is the ability to virtualize any server instantly, in case one dies, or is mis-configured, or needs downtime for maintenance, or some user somewhere deleted or made dumb edits to a file they want restored, or whatever. Currently the company I work for is paying another company a lot of money to do this exact thing. I propose we save some money, have more control over our systems, reduce the number of companies that can make a dumb security decision and leak all of our data, and on top of all of that this new system is managing more computers than the paid system did. So, using only spare hardware and free software, I built this new backup system that'll save us from many hardware and software failures. It's not as good as going full P2V, but I can't get the boss the approve that budget yet, so for now we're going with this free system.


# How to do it
### Get a bunch of storage

I was pleasantly surprised at how many available 500 GB HDDs we had. Not all of them were sitting around waiting for me, but I was able to consolidate some servers and scavenge old machines to free up 'improperly utilized' parts.

I got REALLY lucky with an unused 16-bay NAS for all of my disks. None of you will get that lucky, so look into setting up some FreeNAS/Linux boxes and using a network-spanning RAID-flavored filesystem or something. 

### Make that storage available to the hypervisor

You'll also want to know what hypervisor you're using by this stage. I enjoy XenServer, and I like the idea of KVMs but I just can't get them to work nicely. I eventually went with Hyper-V which I respect as a very powerful hypervisor; it's a shame it's only available on a stupid operating system. Windows was not designed with users in mind. I don't mean this as a reference to anti-consumer behaviors by Microsoft, I mean that having separate and secure user accounts was baked into Unix before Linux or BSD were ever a dream, and as recently as Windows 98 clicking "Cancel" at the logion screen dropped you to the desktop of the default user. Obviously the consumer-facing side of things have dramatically improved, but behind the scenes we're still using these odd shades of 'users' to run services like "Network Service" and "Local Service". This works well enough until you try to give "Local System" access to a Samba share. Guess what all of the Hyper-V services are required to run as?

It was for this ranty reason that I decided to make my storage collected in step 1 so long ago play host to an iSCSI volume, mounted exclusively on the Hyper-V Server. This may not work for you if you want a cluster of hypervisors, but I think a cluster is overkill. Stick a lot of RAM in one machine, and it'll run a few of your servers at mediocre speeds for long enough for you to fix whatever problem caused you to spin up a VM in the first place.

If you want to use a Unix-based OS for your hypervisor, obviously you can just mount the share with fstab and use the credentials your NFS/Samaba/iSCSI/FCoE/whatever server is looking for and then tell fstab to use uid, gid, file_mode, and dir_mode to give access only to the services and users you want. 

### Setup your hypervisor

We really are spoiled for choice among free hypervisors. I think that all of them use either QEMU, Xen, or KVM, except for Hyper-V, but I haven't looked into it much. Here's what I have looked into:

XenServer is the easiest hypervisor I've ever used, and it can be managed from Windows, Linux, local console, SSH, and even a third-party option for web management. Plus it runs on Linux (CentOS 6 I think is the default distro). All of these things put it at the front of my list when testing hypervisors. Unfortunately, it requires that all VHDs come in through the 'front door' by importing each and then setting up a VM to use that. If you set up a XenServer VHD repo and put a few VHDs in there the 'right way' and then put others in there the any other way, XenServer pretends it can't see those other VHDs. There are a few ways to force this to work, but I didn't want the crux of my emergency backup system to be so kludgey. 

Ubuntu Server gives you a tasksel option for a KVM server during installation, so that was a simple installation. Half of this worked great. I could point to any arbitrary VHD and say "boot from this" and it would. I wasn't able to get a third-party GUI management interface working, and there's no way my boss would be OK with using SSH to proxy a VNC connection to interact with the VM's local console. I thought that Canonical's Landscape service might have a KVM management interface, but it wouldn't give me the time of day until I had 5 other servers plugged into it. I briefly considered spinning up a few VMs just to fulfill that odd requirement, but then I was having trouble booting Windows VMs, and that crossed the threshold of too many big problems, and I dropped it for the next hypervisor.

I briefly played with VMware and Proxmox, but I didn't like either of their only management interfaces, so I dropped those before giving them a fair shake.

Finally I came to Hyper-V which did everything I needed it to well, and even most of the things I wanted it to. Also I like to tell myself that Hyper-V virtualizing Windows is more efficient than Xen or QEMU virtualizing Windows. Hyper-V running on 2012r2 core is freely available after you sign up for a free Microsoft account. The management interface is my biggest complaint. It's a great interface: way more power than XenCenter, moderately intuitive, look fine, but it only runs on a small subset of Windows computers. To install any Windows Server management software (Like Hyper-V manager), you have to be running the same or a newer version of Windows as the server you want to manage. Since 2012r2 is the only option currently available, I need to be running Windows 8.1, 2012r2, 10, or 2016. Windows 2016 isn't even out yet, and most people don't make a habit of installing server OSs on their workstations anyway, so that leaves 8.1 and 10. No one likes 8 or 8.1, so we can cross that out, leaving only 10. Windows 10 is a fine OS and there are even many people who have installed it on purpose, but my main machine runs Kubuntu and Windows 7. You can get a preview of Windows 2016 and a trial of Windows 2012r2 or 8.1, but all of those expire after a few months. Don't get me wrong, it's a generous trial, but I don't even want a machine dedicated to managing another single machine, and I certainly don't want to reinstall that management machine over and over. However, that's exactly what I did when I installed the 2016 Technical Preview in XenServer, because you don't want your management interface to die when anything goes wrong with the thing its managing. It's not all bad, the Windows Server Manager is really sweet, and RDP is a fine protocol to remotely connect to a virtual machine that exists only to remotely connect to another machine that exists only to allow connections to its virtual machines.

### Make the storage available to your backup clients

Since I gave exclusive access of my fancy new NAS to the Hyper-V server, I then had to create a CIFS share on that iSCSI volume so others could access it. Yes I know, sharing a share is dumb, but the bottleneck in this whole process is making the VHD from the slow mechanical hard drives of our clients, so the extra protocol overhead isn't a problem on my gigabit network. When actually virtualizing the clients, I'm running right off of the iSCSI with no CIFS in the way, and since my Hyper-V server could never fit 16 disks in it, the 14 disks working in tandem is much faster than I could ever get locally, even squeezed through iSCSI on a crowded network. 

### Edit disk2vhd_automatic.bat

There are a few sections that need editing to fit your exact layout. For example, your VHD repository is probably not named OMITTED, so you'll want to replace most of those instances with your own name. 

There's another section near the beginning that lists the 9 or so servers I want to run disk2vhd_automatic.bat on. Like I commented, those are hard-coded in there because Windows Vista/2008 and newer all use a BCD partition to actually boot from and you'll need to include that in your VHD if you're going to have any hopes of booting your VM. Because not all disks are partitioned equally, the actual location of that BCD partition can change. Open the Disk Management console on each of your newer clients and jot down the number of the partition you boot from. Remember that the Microsoft diskpart program counts disks from 0 and partitions from 1. Truly: Foolish consistency is the hobgoblin of small minds. All of my clients boot from the first disk, so I just hard-coded a "echo sel disk 0 > dpart_start.txt" after a redundant deletion and right before the IF forks of partition selection starts. Cut that line and paste it into each IF fork if your situation is different. 

Speaking of which, also rename each of the clients not actually named OMITTED.

At the end of the script I send an email of failures using Blat. You'll want to change the mail relay server to one that works, and the destination address to one that cares.

Also edit disk2vhd_cleanup.sh for the same reasons.

### Schedule disk2vhd_automatic.bat

Task Scheduler is a great tool, and the Vista/2008 version is even better than crontab. Run as a user with access to the VHD repo, and also as admin. 

Stick disk2vhd_automatic.bat in a local directory on the client and in the same directory also put [blat.exe](http://www.blat.net "A good command-line mailer for Windows") if you want email alerts, and also [Disk2VHD.exe](https://technet.microsoft.com/en-us/sysinternals/ee656415.aspx "The reason we're all here") if you want it to do anything.

If your Windows Task Scheduler is broken, fix it. If you don't want to, I have used Ka Firetask for other projects in the past and that worked well for me. Good luck finding a good place to download it, though.

### Schedule disk2vhd_cleanup.sh

It's a super simple script (last I checked it's 15 lines of function and 25 lines of comments) so you can rewrite it in PowerShell if you want, but both my NAS and urBackup are running with Linux, and I don't want any delete script to run automatically on my NAS, so my urBackup machine was given limited access to the disk2vhd_automatic.bat files, and I set up the unprivileged user's crontab to clean up every weekday at 8am with

	0 8 * * 1-5 /home/OMITTED/scripts/disk2vhd_cleanup.sh

### Test everything!

Be careful to not let the virtual versions of your clients be on the network at the same time as your metal clients. Never cross the streams. I'd recommend not even giving them a NIC until you're ready for potential prime time.



# Optional stuff

### More backups!

Odds are your servers store a lot of files, and some of those files change pretty often. The previous IT guy who set up all of our servers made a lot of bad decisions that I would not have made, and also made some good decisions I would not have made. One of these decisions was partitioning some hard drives between "OS" and "Data". I think this counts as a 'bad' decision, because one of my servers can't get through a Patch Tuesday without running down to 0 free bytes on its C:\ drive and failing some of its updates. Some of our servers have an "OS" hard drive and a "Data" hard drive. I think this counts as a 'good' decision. In both cases this serves me well for backups. I use Disk2VHD to make fairly small VHDs (still ~50 GiB, so not tiny) of the OS volumes and I use another fantastic program called UrBackup to make VHDs of the "Data" volumes.

[UrBackup](https://www.urbackup.org "Another great backup program") is a beautiful, [open source](https://github.com/uroni/urbackup_backend "UrBackup's GitHub page") backup service that can also stick live hard drives into VHDs. I haven't been able to get these VHDs to boot, but I also haven't tried very hard. I suspect that assigning a letter permanently to the BCD partition and telling urBackup to image both of those, and then running urBackup's new VHD stitching script might help. It would be nice to get that working, because one of urBackup's features is incremental VHDs! This really is the best, and way more important to this project than urBackup's decent web management front-end, its great cross-platform support for both servers and clients, its mediocre logging, its VHD compression options (which Hyper-V sadly doesn't support), its easy setup, and its mediocre configuration options. A full disk image of my clients requires between 400 and 600 GiB each, but an incremental image only costs between 1 and 100 GiB each, depending on how much has changed between snapshots. This is a huge cost saving feature, Hyper-V supports it, and I love it.
