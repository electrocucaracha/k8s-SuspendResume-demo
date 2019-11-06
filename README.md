# Suspend and resume demo project
[![Build Status](https://travis-ci.org/electrocucaracha/k8s-SuspendResume-demo.png)](https://travis-ci.org/electrocucaracha/k8s-SuspendResume-demo)

This project was created to validate the suspend and resume
capabilities offered by Libvirt. It uses [Virtlet][1] as Kubernetes
CRI implementation for the creation of containerized Virtual Machines.

## Setup

This project uses [Vagrant tool][2] for provisioning Virtual Machines
automatically. It's highly recommended to use the  *setup.sh* script
provided by the [bootstrap-vagrant project][3] for installing Vagrant
dependencies and plugins required for its project. The script
supports two Virtualization providers (Libvirt and VirtualBox).

    $ curl -fsSL http://bit.ly/initVagrant | PROVIDER=libvirt bash

Once Vagrant is installed, it's possible to deploy the demo with the
following instruction:

    $ vagrant up

Vagrant will provision an Ubuntu Xenial All-in-One Kubernetes cluster
using the [Kubespray tool][4] and configure/install [Virtlet][1] and
[CRI Proxy][2] on every defined worker node. Once the cluster is
up and running, the **virtlet.sh** bash script located in tests folder
will execute a test.

## License

Apache-2.0

[1]: https://github.com/Mirantis/virtlet
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
[4]: https://kubespray.io
[5]: https://github.com/Mirantis/criproxy
