# Quality of Service classes (Demo)
[![Build Status](https://travis-ci.org/electrocucaracha/k8s-SuspendResume-demo.png)](https://travis-ci.org/electrocucaracha/k8s-SuspendResume-demo)

This project was created to understand how supend and resume Libvirt
actions impact different Kubernetes Quality of Service (QoS) classes.
It uses [Virtlet Mirantis project][1] to spawn Virtual Machines in
Kubernetes.

## Concepts

Getting a better understanding of Limits and Resources in Kubernetes
is essential to understand QoS classes.

### Request and Limits

Kubernetes delegates the resource management to the container runtime
(docker/containerd in this case), and the container runtime delegates
to the Linux kernel.

Generally speaking requests are important at schedule time, and limits
are important at run time.

* **Resource request** is a critical input to the scheduler. Unlike
  Memory requests setting a CPU request also sets a property on the
  `cgroup` that helps the kernel actually allocate that number of
  shares to the process.

* **Resource limit** is important to the Kubelet, the daemon on each
  node that is responsible for pod health. Limits are also treated
  differently from memory. Exceeding a memory limit makes your
  container process a candidate for oom-killing, Kubernetes will kill
  that pod and move on. Enforcement of CPU limits ends up being a bit
  trickier, because Kubernetes does not terminate pods for exceeding
  CPU limits.

So what happens if you set a request with no limit? In this case
Kubernetes is able to accurately schedule your pod, and the kernel
will make sure it gets at least the number of shares asked for, but
your process will not be prevented from using more than the amount of
CPU requested, which will be stolen from other process’s CPU shares
when available. Setting neither a request nor a limit is the worst
case scenario: the scheduler has no idea what the container needs,
and the process’s use of CPU shares is unbounded, which may affect the
node adversely.
 
### Quality of Service classes

Pods that need to stay up and consistently good can request guaranteed
resources, while pods with less exacting requirements can use
resources with less/no guarantee.
 
* **Best Effort** pods are dangerous because Kubernetes has no idea
  where to put them and when to kill them so it’s forced to guess.

* **Burstable** pods are good for cost optimization. They limits the
  possibility of node CPU starvation, but it doesn’t eliminate it.
  If one pod expands out (aka. noisy neighbor) at one time is OK. We
  know that our pod is going to be busy from the start and if the pod
  self-heals quickly maybe you can tolerate those short outages.

* **Guarantee** pods are considered top-priority and are not be killed
  until they exceed their limits. They remove the possibility of
  scaling out into more CPU, but it reserves the exact amount that
  your containers are going to need.
 
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

Vagrant will provision an All-in-One Kubernetes cluster using the
[Kubespray tool][4] and configure/install [Virtlet][1] and
[CRI Proxy][2].

## License

Apache-2.0

[1]: https://github.com/Mirantis/virtlet
[2]: https://www.vagrantup.com/
[3]: https://github.com/electrocucaracha/bootstrap-vagrant
[4]: https://kubespray.io
[5]: https://github.com/Mirantis/criproxy
