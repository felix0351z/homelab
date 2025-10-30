With this repo, I would like to show you how I set up my home lab and what I use it for.

## Mini ITX-Build
To run my homelab, I decided to build myself a small Mini-ITX system that is capable of running a NAS and several other services without overloading the power grid. 

After a while, I came up with these components:

| Component   | Model / Specification                    |
| ----------- | ---------------------------------------- |
| Processor   | Intel i3 12100                           |
| Motherboard | GIGABYTE H610I DDR4                      |
| RAM         | G.Skill Aegis 32GB DDR4 (NON-ECC Memory) |
| CPU Cooler  | Noctua NH-L9i-17xx                       |
| SSD         | Crucial T500 1TB                         |
| Hard Drives | 2x Seagate IronWolf NAS HDD 4TB          |
| PSU         | Corsair RM 650 (2023)                    |
| Case        | Fractal Design Node 304                  |

## Proxmox
Later, I installed Proxmox on the machine so that I could run TrueNas Core as my NAS operating system and Ubuntu for my Docker compose stack. 

- I also considered using TrueNas Scale as my main operating system, as it also supports to run apps, but then I wouldn't have been as flexible as with Proxmox
- I chose ZFS as the file system so that I can create snapshots etc.
## TrueNas

| Component       | Specifcation                                 |
| --------------- | -------------------------------------------- |
| Memory          | 12 GiB                                       |
| Processors      | 4 [host]                                     |
| BIOS            | Default (SeaBios)                            |
| Display         | Default                                      |
| Machine         | Default (i440fx)                             |
| SCSI Controller | VirtIO                                       |
| Hard Disk #0    | 32GB Local ZFS Storage (To run TrueNas Core) |
| Hard Disk #1    | 1. Seagate IronWolf NAS HDD 4TB              |
| Hard Disk #2    | 2. Seagate IronWolf NAS HDD 4TB              |
| Network Device  | VirtIO                                       |
### Installation
The downside of virtualising TrueNas is that I have to prasstrough my Hard-Drives so that TrueNas can use them.

Create the TrueNas VM and then open a terminal on your Proxmox host
```bash
sblk -o +MODEL,SERIAL # See all available disks with there Model and Serial number
ls /dev/disk/by-id/ # Get the full disk id
qm set <VM-ID> -scsi<N> /dev/disk/by-id/<DISK-ID> # Mount the disks to the vm

nano /etc/pve/qemu-server/<VM-ID>.conf # Configure the disk configuration
```

Finally, add the serial number for each disk. 
If you don't do this, TrueNas will issue a warning.
```
scsi1: ...,serial=<SERIAL> 
scsi2: /dev/disk/by-id/ata-ST4000VN0063CW104_ZW630DA6,size=3907018584K,serial=ZW630DA6 
scsi3: /dev/disk/by-id/ata-CT120BX500SSD1_1915E17BFF52,size=117220824K,serial=1915E17BFF52
```

### Pool
I have setup a mirrored pool with my Seagate Hard Drives. 
The pool size is therefore 3.64 TiB

#### Datasets & Services

| Path                         | Description                | Permissions              | Permission Type | Service |
| ---------------------------- | -------------------------- | ------------------------ | --------------- | ------- |
| /mnt/pool/Felix              | Private Samba share        | Only me                  | ACL             | SMB     |
| /mnt/pool/Share              | Share for the whole family | The family group         | ACL             | SMB     |
| /mnt/pool/nfs/docker-volumes | Space for docker services  | Ubuntu VM (IP-Adress)    | POSIX           | NFS     |
| /mnt/pool/nfs/proxmox        | Proxmox Backups            | Proxmox Host (IP-Adress) | POSIX           | NFS     |
| /mnt/pool/goodnotes          | GoodNotes Backup           | Default WebDAV User      | POSIX           | WebDAV  |

#### Permissions for NFS
Unlike Samba or WebDav, NFS doesn't have a real authorization system. Access to shares is tied to a specific IP-Address or the entire network. To mention, it is possible to use ACLs since NFSv4, but the complexity it adds to the system is huge and problems are most likely inevitable.
For this reason, I am currently only use NFS authorization at the IP level and honestly, this is enough for my setup. 

However, POSIX Permissions are still valid even if NFS is tied to IP-Addresses. This means that the container who wants to access TrueNas must also use the same UID and GID as specified in TrueNas. 

The simplest solution for this is to map all incoming users to root. With this you want have any permission access problems. But it isn't the most elegant solution if everyone has access to everything. 

Therefore I created a user and group for each service and assigned the shares to them. 

| Path                                      | Maproot User | Maproot Group | Mapall User | Mapall Group |
| ----------------------------------------- | ------------ | ------------- | ----------- | ------------ |
| /mnt/pool/nfs/docker-volumes/immich       | docker       | docker        |             |              |
| /mnt/pool/nfs/docker-volumes/paperlessngx |              |               | paperles    | docker       |
| /mnt/pool/nfs/docker-volumes/vaultwarden  |              |               | vaultwarden | docker       |
| /mnt/pool/nfs/docker-volumes/karakeep     |              |               | karakeep    | docker       |
| /mnt/pool/nfs/proxmox                     |              |               | proxmox     | proxmox      |

Immich as special case: The uid/gid is here defined in compose.yaml. 
## My Docker services

[Immich](https://github.com/immich-app/immich): My preferred solution for storing & sharing images and videos <br>
[Paperless-Ngx](https://github.com/paperless-ngx/paperless-ngx): Management system for all my pdf documents <br>
[Vaultwarden](https://github.com/dani-garcia/vaultwarden): Simple password manager <br>
[Karakeep](https://github.com/karakeep-app/karakeep): I've recently tried Karakeep to save my bookmarks <br>
[Glance](https://github.com/glanceapp/glance): Glance provides a simple but beautiful dashboard <br>
[Portainer](https://github.com/portainer/portainer): To manage my docker stack. However, I actually use the terminal most of the time. <br>
[Nginx Proxy Manager](https://github.com/NginxProxyManager/nginx-proxy-manager): My reverse proxy <br>
