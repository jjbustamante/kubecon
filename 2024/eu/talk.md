Let's start for reviewing our current folder structure when creating a buildpack and 
let's use our hello-world sample buildpack from the cloudnative buildpack samples repo.

when we do tree under the hello-world folder we can see:
- We have a buildpack.toml file in the root folder
- We have a bin folder containing two binaries: build and detect
This is the minimun requiriments for creating a buildpack package, but it shows us the limitation
when a Buildpack Author wants to create a multi-arch buildpack. 

There is an new RFC that proposes a new way of organizing the binaries if we want to create a multi-arch Buildpack or Builder. How does it look like?
The RFC we can separate our binaries according to the os/architecture and then pack will take care of looking for the correct platform root folder
when packaging a multi-arch Buildpack.

Let's apply these changes to the hello-world Buildpack from our samples repo.
After applying all our changes, the hello-world Buildpack folder structure looks like this

And similar to a new folder structure the RFC suggest we need to do add Targets definition to the buildpack.toml

Let's now create our multi-arch hello-world Buildpack

Running our pack binary and using the publish flag, we'll see pack will read the buildpack.toml, it will take all the Targets and for each one it will
try to determine the correct platform root folder, then it will create a OCI image for the particular os/arch and push that image into the registry. Once 
all the intermediate images has been created, pack will create an Image Index to combine them and push that Image Index into the registry.

If we use crane to inspect the Image Index created, we will notice it was created for all our specified targets.

Awesome, for the purpose of saving some time during the demo, we will run similar steps for our hello-moon Buildpack in the background.

How do we create multi-arch composite buildpack?

Let's use our hello-universe sample Buildpack to demonstrate what is required for building a multi-arch composite Buildpack

First off all, we need to update the package.toml file with the Targets os and architectures, this is another change proposed in the RFC

After running our pack buildpack package command using the modified package.toml, we'll notice also an Image Index was created for our hello-universe 
composite buildpack

Again, for the purpose of this demo, we will build a multi-arch build and run images in the background to speed up our demonstration.


Ok! now that we have multi-arch buildpacks, builder and run images. It's time to create a multi-arch builder
Similar to our previous cases, the RFC proposed we need to define some Targets and for builders the way to do it is to update our builder.toml file
It is important to mention that creating multi-arch builders assume we already have our buildpacks, build and run images behind an Image Index for all the targets
we defined.

We run our pack builder create command, and pack will look for each target the corresponding dependencies and create the intermediate builder images and once
it's done, it will create the Image Index and push it into the registry.

If we take a look at our Image Index, we will see our platforms in there.

Finally let's take a look into the Builder image using dive tool and inspect the layers.
