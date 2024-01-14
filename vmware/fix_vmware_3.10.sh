#!/bin/bash
cd /tmp
curl -O http://primepage.de/stuff/vmware/vmblock-9.0.2-5.0.2-3.10.patch
curl -O http://primepage.de/stuff/vmware/vmnet-9.0.2-5.0.2-3.10.patch
cd /usr/lib/vmware/modules/source
cp vmblock.tar vmblock_backup.tar
cp vmnet.tar vmnet_backup.tar
tar -xvf vmblock.tar
tar -xvf vmnet.tar
patch -p0 -i /tmp/vmblock-9.0.2-5.0.2-3.10.patch
patch -p0 -i /tmp/vmnet-9.0.2-5.0.2-3.10.patch
tar -cf vmblock.tar vmblock-only
tar -cf vmnet.tar vmnet-only
rm -r vmblock-only
rm -r vmnet-only
vmware-modconfig --console --install-all
