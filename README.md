# Weather Infra
This repository handles creating the infrastructure behind the entire air quality project so that it can be deployed on a cloud solution. There are several steps to get everything configured, so I will do my best to ensure that everything is explained as in-depth as possible. It is also good for me to do so so when I come back and need help with deploying cloud solutions, I can reference this without being confused.

### Note
Please be aware that this solution looks to deploy everything to a single GCP Compute Engine instance. Understandably, this is not used in industry or even desired. However, for my personal development and both cost incurred for more in depths solutions like Vertex AI, this is more than enough for this current project. As time goes on, and with other projects, I may explore a cloud-first solution rather than local development. For now, this solution for this project works, and I will aim to explain how it could be improved. Before starting, make sure you are logged in

```bash
gcloud auth login
gcloud auth application-default login
```

### Docker
Since applications inside the compute engine will be deployed with docker and docker compose, we should ensure that those are installed on startup of the compute engine. There is `scripts/startup.sh.tpl` file that specifies the installation instructions, as well as adds the user to the docker group, so there is no need to run `sudo` commands to access the Docker daemon. When you first SSH into the VM, you will need to exit, then re-enter for the change to actually take effect on your user. Then you should be able to run the commands without issue!

### Service Accounts and Terraform
#### Terraform Setup
Given how much there is to set up for this simple application alone, I wanted to use Terraform to make creation and destuction of these objects much simpler for myself. Terraform is so valuable since it makes the creation of cloud products the same whenever you run `terraform apply`. Within this example specifically, I want to create a simple google compute instance that will host everything. I use dockerhub to store the images that will be changing frequently with CI/CD, so I need to ensure that the compute instance has access to the internet with egress. Secondly, for a little bit of security (although security could be configured much better than what is shown here), I restrict SSH access to only allow my local IP address. To get my local IPv4 address, you can run a request again ipconfig.me

```bash
curl -4 http://ipconfig.me
```

This will return your machine's personal IP. Please make sure to store this IP, and any other personal information like GCP project ID, user email, etc, in a `.tfvars` file. This is highly sensitive information that should be protected. 

Additionally, there are some services with this application that we would like to access the UI for like MLFlow, Minio, Grafana, etc. In order to be able to access these services, we need to allow ingress for our machine to these services. In the same fashion as ssh, we restrict these to only allow access from our machine via our personal IP address. When these services are deployed, we should be able to access the UI for each of them respectively using the compute engine's external IP. This can be found by navigating to the specified projects compute engine instances on Google Cloud, where you will find the external IP for these services. This logic is defined in the `main.tf` file. 

#### Service Accounts
Since I am using github actions for CI/CD, there is the need to create a service account that will be able to access the compute engine instance to pull the newest images when they are built. Now, there are several roles created in order to allow this service account access to the compute engine instance. These roles are all needed and should not be removed. When creating the service account, ensure that this is also kept private. This will have certain admin privileges that you will not want to be exposed so be extra careful. Additionally, to configure github actions to be able to pull and push images, we need a key associated with the service account. This service account key is PRIVATE and needs to be prevented from being uploaded to any repository. When terraform creates the compute engine instance with `terraform apply`, it will save the key in a `service_account_key.json` file on your local machine. You need to upload the contents of that file to the proper github repositories as a github actions secret variable, as that will allow access. 

### Spinning Up and Accessing
To spin up and create the VM with these rules, first make sure that you have the correct gcloud project set
```bash
gcloud config set project <project_id>
```

Using the project ID to your specific project. Then, you can run 

```bash
terraform plan
terraform apply
```

Which will handle creating the VM, along with the necessary IAM roles associated with your user and the service account. When this is done, you can then SSH into the VM with

```bash
gcloud compute ssh <your_vm_name> --zone=<your_zone>
```

Since we have OS Login enabled, Google Cloud will handle the ssh keys for us. Now, when everything is spun up and working, there are a few important things that are needed for the various projects. Since we are using Github Actions for CI/CD, we need to store the following as github secrets to be used during the image build and deploy processes:
- Your linux username in the VM
- Your service account secret key
- The name of the created VM
- Your GCP project ID

We currently store the images on dockerhub, so you would also need:
- Your Dockerhub username
- Your Dockerhub secret keys (can be generated on Dockerhub)
- Your Dockerhub repository name
- Your Docker network to run the image on (Only applicable if using the same network)

Whenever you are configuring Github actions, make sure to add these under secrets.

### Post Setup
Once the setup portion of the VM is complete, we will want to start to deploy our services on it. There is an example `docker-compose.yml` file here that contains the different services used throughout this project that can be deployed under a single compose file. This makes it far more easy since we do not need multiple compose files to spin up the containers. Also, using Github Actions, we can spin up those images as containers and refer the proper network when running the image. That way, any images that will be using CI/CD do not require us to consistently rebuild all of the Docker containers. For any environment variables needed for this compose file, as well as the other portions of this project, the `.env.example` file contains examples of how to configure your environment variables. Then, simply copy this over to the vm, and run

```bash
docker-compose up -d --build
```

And it will start all of our containers in the VM. Then, we can run our individual containers by pulling them from Dockerhub into the VM, and running them with `docker run ...`. Be sure to specify the `--env-file` and `--network` arguements if needed. From there, everything should be able to be configured and run without issues!

Please also be aware that the rust consumers and producers needed for this project require a `config.toml` file to store the needed lat/long and database url's for this project. The file should be set up as so

```toml
[location]
latitude = 50.0000
longitude = -50.0000

[database]
db_url = "postgres://your_user:your_pass@your_address:5432/your_db"
```

And should be stored in the same location as the `.env` file on the engine (in the users home directory).

In order to create a single network for weverything to use (and rather than relying on Docker naming the network), we could create the network with

```bash
docker network create -d bridge example-net
```

This will create the named network that we can pass to any docker image or
container that will run on the GCP Compute Engine instance. We would just then
need to add to the compose file that the network comes from external, ad we are
all set.

### Additional Notes
I understand that this setup is not practical for actual production level solutions. However, I am trying to refamiliarize myself with cloud platforms after not touching them for quite some time. You may want to instead use Google Artifact Registry, Vertex AI, Kubernetes Engine, etc, to configure all of your services. I do not have the funds nor the time to explore all of that right now. I'm happy enough with this solution as is, but will explain more on how this project could be furthered. Perhaps as I complete other projects, I can explore these solutions on GCP, as well as other platforms like AWS and Azure. But, given how much work I have put into this project as a whole, I am overjoyed at what I have been able to come up with. 
