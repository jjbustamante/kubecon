## KubeCon EU 2022

I used this sample code during the [kubecon EU 2022](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/) 
Offices Hours. The idea is to demonstrate how to install Kpack on a kubernetes cluster and use it to build the sample 
Go application

### Before
- Access to a Kubernetes cluster is require, in my case, I am using Kubernetes on [Docker](https://docs.docker.com/desktop/kubernetes/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) tool must be configured to connect with Kubernetes cluster
- Install [kp](https://github.com/vmware-tanzu/kpack-cli) command line tool

### Prepare Kpack

- Install Kpack
    ```bash
    kubectl apply -f https://github.com/pivotal/kpack/releases/download/v0.5.3/release-0.5.3.yaml
    ```
- Create the secret to be use to get access to my registry. (Note I am using a token for my particular registry)
    ```bash
    kp secret create gcr-secret --gcr ~/Downloads/cnb-playground-f62a47df5739.json
    ```
- Create a service that reference the secret created before
    ```bash
    kubectl apply -f service.yaml
    ```
- Create a cluster store configuration
    ```bash 
    kubectl apply -f store.yaml
    ```
- Create a cluster stack configuration
    ```bash
    kubectl apply -f stack.yaml
    ```
- Create the builder to be used to create our application image
    ```bash
    kubectl apply -f builder.yaml
    ```

### Let's build our image

Once [Kpack](https://github.com/pivotal/kpack) environment is ready, let's build our image

- Create an image resource that [Kpack](https://github.com/pivotal/kpack) should build and manage
  ```bash
   kp image create sample-go-app --tag gcr.io/cnb-playground/sample-go-app-kubecon --git https://github.com/jjbustamante/go-sample.git --git-revision main --builder go-builder --env BP_KEEP_FILES='static/*' --wait
  ```
  Once the command executed the application image must be created and push into your repository registry
- Download the created image into our local daemon
  ```bash
  docker pull gcr.io/cnb-playground/sample-go-app-kubecon
  ```
- Execute the application locally
  ```bash
  docker run --rm -p 3000:3000 gcr.io/cnb-playground/sample-go-app-kubecon
  ```
  Open a browser and check the [application](http://localhost:3000)
- Do some changes to your code, push it to your git repo and check a new build should be started
- Once the build is finished, download the new image, run the app locally and check again

