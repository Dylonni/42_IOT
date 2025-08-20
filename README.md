# Inception Of Things (IOT)

**IOT** is a project where you learn the basics of container orchestration by implementing your own working cluster with Kubernetes !   

This project is separated in **3 Parts**, which go deeper into the understanding of Kubernetes, but also Vagrant and the **Continuous Delivery** tool : **ArgoCD**.  

> [!NOTE]  
> Each part READMEs are located into their respective folders inside the repository to break them down. This **README** serves as a cheat sheet for the commands that will be used throughout the project.

---  
  
![VAGRANT](https://img.shields.io/badge/Vagrant-1868F2?style=for-the-badge&logo=Vagrant&logoColor=white)
| Command | Description |
| :--- | ---|
| vagrant up | Execute the **Vagrant** file in the current folder |
| vagrant ssh `<VM name>`   | Connect via ssh to the VM  |
| vagrant destroy   | Destroy the spinning VMs  |

---

![K8S](https://img.shields.io/badge/Kubernetes-3069DE?style=for-the-badge&logo=kubernetes&logoColor=white)
![K3S](https://img.shields.io/badge/K3S-FFC61C?style=for-the-badge&logo=k3s&logoColor=black)

| Command | Description |
| :--- | ---|
| kubectl get nodes  | Show informations about **Nodes** |
| kubectl get pods| Show informations about **Pods** |
| kubectl get service | Show informations about **Services**   |
| kubectl get ingress | Show informations about **Ingress**  |
| kubectl get ns | Show current created **Namespaces**  |
| kubectl get all | Show informations about  **Pods**, **Services**, **Deployments** and **ReplicaSets**  |
| kubectl delete pod `<POD NAME>` | Delete the matching Pods |
| kubectl create namespace `<NAME>` | Create a **Namespace** named `<NAME>` |
| kubectl apply -f `<PATH/FILE.yml>` | Apply new settings from yaml file to the cluster |

---
### K3d

| Command | Description |
| :--- | ---|
| k3d cluster create `<CLUSTER NAME>` | Create a cluster named `<CLUSTER NAME>` |
| k3d cluster list | List existing clusters |
| k3d cluster delete `<CLUSTER NAME>` | Delete cluster named `<CLUSTER NAME>` |
| k3d cluster delete -a | Delete every clusters |
