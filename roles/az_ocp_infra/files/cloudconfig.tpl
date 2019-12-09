#cloud-config
write_files:
-  content: |
     test
     test
    owner root:root
    path: /usr/bin/bootstrap_host
    permissions: 0740
runcmd:
- echo "test" >> /myfile
# - subscription-manager register
# - yum -y install python3-pip
# - pip3 install ansible