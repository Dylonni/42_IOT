# Part 3 : K3d and Argo CD

This is the last part of the project. Inside this part we will learn about **Continuous Delivery** (CD), which is a concept that plays a big role when creating and deploying scalable apps.

Firstly, i will address the difference between **K3s** and **K3d** while we are at it, cause it's required for the project :

### K3s
As explained in part 1, **K3s** is a lightweight version of **Kubernetes** (***K8s***), it's designed to run clusters inside minimal resource environments like a VM for example.
> [!TIP]
> Fun Fact: the **'3'** in K3s is the **'8'** from K8s : split in half !
> The creators named it that way to represent the fact that K3s is less requiring then K8s.

### K3d
**K3d** is a **wrapper** for **K3s** making it run inside a **Docker Container** and also automatically configuring it. Remember the setup parts for the **Server** and/or **Workers**? It handles that automatically, so no need to grab tokens or doing manual config !

Although there are multiple tools that can be used for Continuous Delivery, we will use **ArgoCD** which is a Kubernetes-native app.

![ARGOCD](../docs/p3/argocd.png)  

## How does it work, what does it do ?

ArgoCD is a tool that will let you monitor your **Kubernetes Cluster**. You will be able to see what app is running inside your cluster, how many pods/services you have, their sync status, etc..  

Not only that, it will also serve as an automated deployment tool. The idea is that you only need to modify your Git repository in order to make changes to your app. ArgoCD will **watch** on that repository and automatically change your app depending on what's inside the Git repo, it's called a **source of truth** and ArgoCD takes Git as it's source of truth.  

Let's say you want to have more replicas of an existing **Pod** for example.  

**Without ArgoCD** :  
- You would need to go inside your **`deployment.yaml`** file -> edit the numbers of replicas -> apply those changes in your terminal with :
```
$ kubectl apply -f deployment.yaml
```

**With ArgoCD** :  
- You change your **`deployment.yaml`** file inside your Git repo manually (or by commit) -> ArgoCD **sees** that difference and automatically syncs your app. (if you actually set it to behave that way, more on that later...)  

ArgoCD can also be useful for rollback purposes. As every versions of your app are on your Git, you can revert to a certain version of your repo and ArgoCD will sync everything from that version automatically !  

Sounds cool ? Let's install it for our project ! (You don't have the choice anyway)


## Installation Scripts

### Prerequisites  

In order to complete this part, you will have to install some few prerequisites :

- Docker (So k3d can run)
- K3d
- kubectl (Because it's not included inside k3d)

You will find the script to install those inside the **`p3/scripts/prerequisites_install.sh`** folder.  

I will not go through this file because it's quite self explanatory and i wrote some comments inside it for guidance.  

### The Argo-App yaml

Before setting up ArgoCD, let's quick review **`p3/confs/argo-app.yaml`**. As **`argo_setup.sh`** needs it upon installation. 

```yaml
### ------------ 📄 argo-app.yaml  ------------ ###

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: argo-instance
  namespace: argocd
spec:
  project: default 
  source:
    repoURL: https://github.com/Dylonni/iot-daumis-conf.git
    targetRevision: HEAD
    path: wil
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

```

Here are some tags that needs further explanation.  

- **`repoURL`** : the github repository that ArgoCD will watch on. 
- **`targetRevision`** : the specific branch to watch on.
- **`path`** : the specific folder inside the repo to watch on (if there is). 
- **`server`** : where the apps runs (by default it's the kubernetes 'local' cluster, the one where ArgoCD runs). 
- **`syncPolicy:automated:prune`** : deletes ressources that are not inside the Git repo anymore. 

### About selfHealing

The **`selfHeal`** setting in ArgoCD determines how the system reacts when there are discrepancies between the state of the cluster and the state defined in your Git repository.

By default, **`selfHeal`** is set to **`false`**. When set to false, ArgoCD will not automatically reconcile differences between the cluster and Git. Instead, the user needs to manually trigger synchronization.

#### `selfHeal: false`

- **If you modify resources directly in the cluster** (e.g., using `kubectl edit` or `kubectl apply`), ArgoCD will detect that the cluster is **OutOfSync** with the Git repository.  
  To get things back in sync, you will need to either:
   - Modify the Git repository to match your changes, or
   - Click the **Sync** button in the ArgoCD UI to apply the state from Git to the cluster, overwriting the local changes.

>[!CAUTION]  
> Although you can "force" a sync via the ArgoCD interface, this will only make the cluster conform to the state in Git. The cluster's current state will be restored to match the repository, which might not reflect the changes you made manually.

- **If you modify resources in Git** (e.g., pushing a commit), ArgoCD will detect that the cluster is **OutOfSync** with Git.  
  To sync, you can click the **Sync** button in the ArgoCD UI, and the changes in Git will be applied to the cluster, bringing it back in sync with Git.

#### `selfHeal: true`

- **If you modify resources directly in the cluster**, ArgoCD will detect the difference and **automatically** revert the cluster back to the state defined in Git, without any user intervention. This ensures that the cluster will always reflect the desired state in Git, as ArgoCD will continuously monitor and restore it.

- **If you modify resources in Git**, ArgoCD will detect the change and automatically reconcile the cluster to match the new state from Git after a short delay, returning the cluster to a **Synced** state.

---

### Key Differences between `selfHeal: true` and `selfHeal: false`

| Action | `selfHeal: false` | `selfHeal: true` |
|--------|-------------------|------------------|
| Modify resources in the cluster (e.g., `kubectl`) | ArgoCD marks the app **OutOfSync**, you must manually click **Sync** to apply the Git state. | ArgoCD automatically reverts changes and reconciles the cluster to match Git. |
| Modify resources in Git (e.g., commit and push) | ArgoCD marks the app **OutOfSync**, you must manually click **Sync** to apply the Git changes. | ArgoCD automatically applies the changes from Git to the cluster after a short delay. |

> [!NOTE]
> It’s best to make changes in Git rather than modifying resources directly in the cluster. Manual changes in the cluster can create discrepancies between the state defined in Git and the actual state in the cluster, which may lead to misalignment issues.


### About Namespaces

A Namespace is a logical way to isolate and organize ressources, in this project we are required to create one namespace for ArgoCD (named "argocd") in which argocd will run, and another for the development of the app (named "dev").  

Every **Pod** in **dev** will not be able to communicate with a **Pod** in the **argocd** namespace for example.  

Here is a little schema about what it looks like:  
![NAMESPACES](../docs/p3/namespaces.png)  

## Setting Up ArgoCD

> [!IMPORTANT]
> Before running the setup script, you should modify the **`argo-app.yaml`** file. Make it watch your own freshly created repository (and not mine since you can't commit anything to it).

As said, the point of ArgoCD is using Git to make changes to your apps, your **`deployment.yaml`** and **`service.yaml`** files will be located in a remote git repository and no more locally. (We don't use ingress there because we are not routing traffic).  

Your repo should look like this:  

![GTREPO](../docs/p3/gitrepo.png)  

Once the prerequisites are installed and everything is set up, you can run **`p3/scripts/argo_setup.sh`**.  

This will install and configure ArgoCD to be accessible through your web browser. 

Again, the script is self explanatory and comments are there to explain further.

> [!IMPORTANT]
> At some point, this script will try to port forward the service : **`wil-service`**.
>```sh 
> [...]
>
>(line 105) 
>kubectl port-forward -n "$NAMESPACE_DEV" svc/wil-service 8888:8888 &
> 
> [...]
>```
> if the service doesn't exist inside your remote repo, the port forwarding will fail and you will not be able to access your app from your browser nor curl it.
>You either have to set **`wil-service`** in your **`service.yaml`** file on Git, or replace '**`wil-service`**' inside the **`p3/scripts/argo_setup.sh`** file with whatever your service name is on Git.  

> [!TIP]
> These scripts need to be ran in your host machine, not inside another VM that you have to make with **Vagrant** as for the previous parts. Because the whole point is to make ArgoCD and your cluster run inside a **Docker Container**, that's why we use **K3d**.  

If everything is done correctly you should be able to connect to your ArgoCD instance and have a view to your running app.

![ARGOLOGIN](../docs/p3/argologin.jpg)  

Feel free to try and discover the UI !  
If you want to test it, here is a simple test that you can apply :  

- Curl your app to get his message
- Go to your watched repository. 
- Inside **`deployment.yaml`**, modify **`wil42/playground:v2`** to **`wil42/playground:v1`** or vice versa.
- Refresh your ArgoCD page. 

You should see old pods getting destroyed (thanks to prune : true) and ArgoCD deploying and syncing with your new app (taking v1 or v2 images) !  

You can also check these changes with **curl**:  

**Before changes on Git** :  
![CURLONE](../docs/p3/curl1.png).  

**After changes on Git** :  
![CURLTWO](../docs/p3/curl2.png)  

### Congratulations !

You made it ! You now have a pretty good overview about Kubernetes Clusters and Continuous Delivery, you will now be able to respond when somebody talks about CI/CD Pipelines (well at least the CD part of it, CI is another story..)
