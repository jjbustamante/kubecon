

Who am I?
  
  Hi, My name is Juan Bustamante
  I am software engineer at VMware by Broadcom. 
  I am also a Platform maintainer at Buildpacks project. 
  I've been around the industry for more that 15 years now, 
  focus on backend development using Java stacks 
  and most recently with Golang. 
  I've been involved with multi-arch development in the CNB project.
  
What is a multi-architecture OCI image?

A multi-architecture OCI image is based on image manifests and 
an image index (or manifest lists)
Each container image is represented by manifest, which is a 
json file that uniquely identifies the image by referencing 
the configuration file and it's layers.

When we want to support OCI images for different 
OS and architectures, we have to create an Image Index 
in front of a manifest's collection. 
The image index includes details such as the supported OS 
and architecture. 

Let's take a look an example.
Probably familiar with the busybox image, if we inspect 
the manifest using crane tool we will see an Image Index, 
and for the purpose of this demo, we are just showing 2 
manifests. linux/amd64 and linux/arm

What is the Cloud Native Buildpack doing to support building 
multi-arch images?

To support multi-arch images using CNB, the expectation 
is all the components that are distributed using an OCI 
registry must be behind an Image Index. 

Let's see where are we?

In the following compatibility table, we can see on the left
all the components from CNB ecosystem that are distributed as
OCI artifacts, on the right, we can noticed we are in good 
shape for linux/amd64, but, when we check our support for arm
architecture, we have a debt with Buildpack Authors and the 
support for Buildpacks and Builders is not that great yet!

We've been working on a RFC to improve the support for multi-arch
in the CNB ecosystem, and the idea behind this RFC is to add the
capabilities to the pack buildpack package and pack builder create
commands to handle the creation of Image Indexes for you.

The RFC proposes two major things, the first one is a new folder 
structure, for buildpacks authors, to organize their binaries in 
cases where they need it. The second one is to update some 
configuration files to include Targets.

It's time for a demo! 

Fist of all, we are going to use our samples repository and we
are going to execute the changes describe in the RFC to genete
multi-arch buildpacks and builders with a pack binary compiled 
from a PoC branch. Again, this is still a work in progress but
it will be available very soon.

Also we are running a local registry where we will save all the 
OCI artifacts.

let's use our hello-world sample buildpack

when we do tree under the hello-world folder we can see:
- We have a buildpack.toml file in the root folder
- We have a bin folder containing two binaries: build and detect
This is the minimun requiriments for creating a buildpack package, 
but it shows us the limitation when a Buildpack Author wants to 
create a multi-arch buildpack. 

After applying all of our changes, the hello-world Buildpack folder 
structure will look like this

And similar to a new folder structure the RFC suggest we need to add 
Targets definition to the buildpack.toml

Let's now create our multi-arch hello-world buildpack, we run the 
pack buildpack package command, and it will read your buildpack.toml
file, it will realized there are two targets definition and pack is 
going to create a single image for each target, after pushing them 
into the registry, pack is going to create an Image Index in front 
of them and also push it into the registry

If we use crane to inspect the manifest, similar to what we did before
for busybox, we will noticed an Image Index was created for us with the
targets we specified in our buildpack.toml file.



