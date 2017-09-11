Kacper's random notes
=====================

Converting yaml to ign:

```bash
$ wget https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.3.1/ct-v0.3.1-x86_64-unknown-linux-gnu
$ mv ct-v0.3.1-x86_64-unknown-linux-gnu ct
$ chmod +x ct
$ ./ct -platform openstack-metadata -in-file coreos.yaml -out-file config.ign
```
