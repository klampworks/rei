rei
===

A project for managing single application virtual machines

This project is a collection of tools to help manage single application virtual machines. 

Instead of building dedicated systems for each application I have a single squashfs filesystem image containing all applications I want. The single image is then mounted in different virtual machines and each VM configured for its dedicated purpose at boot time. 

By configuring appropriate iptable and selinux rules the only overhead of the surplus applications will be disk space. The advantage is that I have a single master image I can update instead of managing several desperate systems.

I use Gentoo for my base but OS choice is outside the scope of this project. As long as it can boot into a busybox initramfs then the same concept should work.

The purpose of having single application virtual machines is for securing vulnerable network facing applications (web browser, mail client, irc client etc.) and for containing untrusted applications (such as Skype which is borderline malware).

Although this is a fairly heavyweight solution, ram and disk space are cheap. Remounting the same image for each VM cuts down on storage space and if memory is an issue then swap can be used to compensate.
