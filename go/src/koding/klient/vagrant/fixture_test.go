package vagrant_test

const vagrantLsmod = `
Module                  Size  Used by
vboxsf                 43798  1 
nfsd                  284385  2 
auth_rpcgss            59338  1 nfsd
nfs_acl                12837  1 nfsd
nfs                   236726  0 
lockd                  93941  2 nfs,nfsd
sunrpc                289260  6 nfs,nfsd,auth_rpcgss,lockd,nfs_acl
fscache                63988  1 nfs
dm_crypt               23177  0 
joydev                 17381  0 
crct10dif_pclmul       14289  0 
crc32_pclmul           13113  0 
video                  19476  0 
serio_raw              13462  0 
vboxguest             249035  2 vboxsf
aesni_intel            55624  0 
aes_x86_64             17131  1 aesni_intel
glue_helper            13990  1 aesni_intel
lrw                    13286  1 aesni_intel
gf128mul               14951  1 lrw
ablk_helper            13597  1 aesni_intel
cryptd                 20359  2 aesni_intel,ablk_helper
ahci                   34091  1 
psmouse               106692  0 
libahci                32716  1 ahci
e1000                 145227  0 
`

const gceLsmod = `
Module                  Size  Used by
xt_addrtype            16384  2
xt_conntrack           16384  1
ip6table_filter        16384  1
ip6_tables             28672  1 ip6table_filter
xt_CHECKSUM            16384  1
iptable_mangle         16384  1
ipt_MASQUERADE         16384  2
nf_nat_masquerade_ipv4    16384  1 ipt_MASQUERADE
iptable_nat            16384  1
nf_conntrack_ipv4      16384  2
nf_defrag_ipv4         16384  1 nf_conntrack_ipv4
nf_nat_ipv4            16384  1 iptable_nat
nf_nat                 28672  2 nf_nat_ipv4,nf_nat_masquerade_ipv4
nf_conntrack          106496  5 nf_nat,nf_nat_ipv4,xt_conntrack,nf_nat_masquerade_ipv4,nf_conntrack_ipv4
xt_tcpudp              16384  5
bridge                114688  0
stp                    16384  1 bridge
llc                    16384  2 stp,bridge
iptable_filter         16384  1
ip_tables              28672  3 iptable_filter,iptable_mangle,iptable_nat
x_tables               36864  10 ip6table_filter,xt_CHECKSUM,ip_tables,xt_tcpudp,ipt_MASQUERADE,xt_conntrack,iptable_filter,iptable_mangle,ip6_tables,xt_addrtype
dm_crypt               28672  0
dm_thin_pool           61440  1
dm_persistent_data     65536  1 dm_thin_pool
dm_bio_prison          16384  1 dm_thin_pool
dm_bufio               28672  1 dm_persistent_data
libcrc32c              16384  1 dm_persistent_data
ppdev                  20480  0
serio_raw              16384  0
parport_pc             32768  0
parport                49152  2 ppdev,parport_pc
crct10dif_pclmul       16384  0
crc32_pclmul           16384  0
aesni_intel           167936  0
aes_x86_64             20480  1 aesni_intel
lrw                    16384  1 aesni_intel
gf128mul               16384  1 lrw
glue_helper            16384  1 aesni_intel
ablk_helper            16384  1 aesni_intel
cryptd                 20480  2 aesni_intel,ablk_helper
psmouse               126976  0
virtio_scsi            20480  1
`
const vboxManageList = `
"boot2docker-vm" {d4d92435-7863-43ab-9a4a-1b24654abcd8}
"urfv96068ead_default_1456788305661_75135" {54017b76-d33c-4206-98f6-9325cde08e48}
"urfv03793f17_default_1457009883965_98845" {cefb8db4-85a3-46de-9ee3-550f52af284c}
"urfvb829da4e_default_1458138067707_50913" {3e741263-238b-4cb1-8b39-1ec5bda621b5}
"urfv2f0b95fa_default_1458165170610_91726" {2afed5a0-a5f3-4fc9-b959-142c001c1764}
"urfv3087bcb9_default_1458688168519_19611" {a312966d-7149-4b75-8b85-2f2af6c52a57}
"urfv5d427967_default_1458769296011_91134" {1a4c6d7e-e086-4641-814e-117491517a62}
"urfv6f909543_default_1458817158801_33294" {5eb39c47-a615-4d5b-a58f-db2b505a0221}
"urfv00a43819_default_1458893239957_62293" {86263141-27d8-469f-926c-d06412aad918}
"urfve6cb85a2_default_1458910687825_39001" {295e77c3-d922-4849-93de-4422b8c08880}
`

const vboxManageShowvminfo = `
name="urfve6cb85a2_default_1458910687825_39001"
groups="/"
ostype="Ubuntu (64-bit)"
UUID="295e77c3-d922-4849-93de-4422b8c08880"
CfgFile="/Users/rjeczalik/VirtualBox VMs/urfve6cb85a2_default_1458910687825_39001/urfve6cb85a2_default_1458910687825_39001.vbox"
SnapFldr="/Users/rjeczalik/VirtualBox VMs/urfve6cb85a2_default_1458910687825_39001/Snapshots"
LogFldr="/Users/rjeczalik/VirtualBox VMs/urfve6cb85a2_default_1458910687825_39001/Logs"
hardwareuuid="295e77c3-d922-4849-93de-4422b8c08880"
memory=2048
pagefusion="off"
vram=12
cpuexecutioncap=100
hpet="off"
chipset="piix3"
firmware="BIOS"
cpus=2
pae="off"
longmode="on"
cpuid-portability-level=0
bootmenu="messageandmenu"
boot1="disk"
boot2="none"
boot3="none"
boot4="none"
acpi="on"
ioapic="on"
biossystemtimeoffset=0
rtcuseutc="on"
hwvirtex="on"
nestedpaging="on"
largepages="off"
vtxvpid="on"
vtxux="on"
paravirtprovider="legacy"
VMState="running"
VMStateChangeTime="2016-03-25T12:58:09.499000000"
monitorcount=1
accelerate3d="off"
accelerate2dvideo="off"
teleporterenabled="off"
teleporterport=0
teleporteraddress=""
teleporterpassword=""
tracing-enabled="off"
tracing-allow-vm-access="off"
tracing-config=""
autostart-enabled="off"
autostart-delay=0
defaultfrontend=""
storagecontrollername0="SATAController"
storagecontrollertype0="IntelAhci"
storagecontrollerinstance0="0"
storagecontrollermaxportcount0="30"
storagecontrollerportcount0="1"
storagecontrollerbootable0="on"
"SATAController-0-0"="/Users/rjeczalik/VirtualBox VMs/urfve6cb85a2_default_1458910687825_39001/box-disk1.vmdk"
"SATAController-ImageUUID-0-0"="876696e5-e452-4091-997e-9285d968fc1b"
natnet1="nat"
macaddress1="080027089D5F"
cableconnected1="on"
nic1="nat"
nictype1="82540EM"
nicspeed1="0"
mtu="0"
sockSnd="64"
sockRcv="64"
tcpWndSnd="64"
tcpWndRcv="64"
Forwarding(0)="ssh,tcp,127.0.0.1,2200,,22"
Forwarding(1)="tcp56790,tcp,,2201,,56789"
Forwarding(2)="tcp56791,tcp,,2202,,56787"
nic2="none"
nic3="none"
nic4="none"
nic5="none"
nic6="none"
nic7="none"
nic8="none"
hidpointing="ps2mouse"
hidkeyboard="ps2kbd"
uart1="off"
uart2="off"
lpt1="off"
lpt2="off"
audio="none"
clipboard="disabled"
draganddrop="disabled"
SessionName="headless"
VideoMode="720,400,0"@0,0 1
vrde="off"
usb="off"
ehci="off"
xhci="off"
SharedFolderNameMachineMapping1="vagrant"
SharedFolderPathMachineMapping1="/Users/rjeczalik/.vagrant.d/foobaz/urfve6cb85a2"
VRDEActiveConnection="off"
VRDEClients=0
vcpenabled="off"
vcpscreens=0
vcpfile="/Users/rjeczalik/VirtualBox VMs/urfve6cb85a2_default_1458910687825_39001/urfve6cb85a2_default_1458910687825_39001.webm"
vcpwidth=1024
vcpheight=768
vcprate=512
vcpfps=25
GuestMemoryBalloon=0
GuestOSType="Linux26_64"
GuestAdditionsRunLevel=2
GuestAdditionsVersion="4.3.36_Ubuntu r105129"
GuestAdditionsFacility_VirtualBox Base Driver=50,1458910695598
GuestAdditionsFacility_VirtualBox System Service=50,1458910698314
GuestAdditionsFacility_Seamless Mode=0,1458910695598
GuestAdditionsFacility_Graphics Mode=0,1458910695597
`
