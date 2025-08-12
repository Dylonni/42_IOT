# Part 3 : K3d and Argo CD

This is the last part of the project. Inside this part we will learn about **Continuous Delivery** (CD), which is a concept that plays a big role when creating and deploying scalable apps.

Although there are multiples tools that can be used for Continuous Delivery, we will use **ArgoCD** which is a Kubernetes-native app.

![ARGOCD](../docs/p3/argocd.png)

Firstly, let's address the difference between **K3s** and **K3d** while we are at it.

### K3s
As explained in part 1, **K3s** is a lightweight version of **Kubernetes** (***K8s***), it's designed to run clusters inside minimal ressource environments like a VM for example.
> [!TIP]
> Fun Fact: the **'3'** in K3s is the **'8'** from K8s : split in half !
> The creators named it that way to represent the fact that K3s is less requiring then K8s.

### K3d
**K3d** is a **wrapper** for **K3s** making it run on a **Docker Container** and also automatically configuring it. Remember the setup parts for the **Server** and/or **Workers**? It handles that automatically, so no need to grab tokens or doing manual config !

