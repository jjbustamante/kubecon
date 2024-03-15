#!/bin/bash

# Include the "demo-magic" helpers
source demo-magic.sh

DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
TYPE_SPEED=30

function comment() {
  cmd=$DEMO_COMMENT_COLOR$1$COLOR_RESET
  echo -en "$cmd"; echo ""
}

SCRIPT_REPO=$HOME/go/src/github.com/jjbustamante/kubecon/2024/eu
SAMPLES_REPO=$HOME/go/src/github.com/jjbustamante/samples
PACK_BINARY=$HOME/go/src/github.com/jjbustamante/pack/out/pack
cd $SAMPLES_REPO
git clean -f -d 
git checkout .
git pull

clear

# Let's prepare our local docker registry

registry=$(docker run -d -p 5000:5000 --name registry --restart always registry:2)
#repo="jbustamantevmware"
#prefix="docker://"
repo="localhost:5000"
prefix=""

cowsay "Let's start for reviewing our current folder structure when creating a buildpack"
pe 'clear'

pe 'tree buildpacks/hello-world'
pe 'clear'

cowsay "Let's apply the changes proposed in the RFC"
pe 'clear'

cd $SAMPLES_REPO

mkdir -p buildpacks/hello-world/linux/amd64
mkdir -p buildpacks/hello-world/linux/arm64
cp -R buildpacks/hello-world/bin buildpacks/hello-world/linux/amd64
mv buildpacks/hello-world/bin buildpacks/hello-world/linux/arm64
cp buildpacks/hello-world/README.md buildpacks/hello-world/linux/amd64
mv buildpacks/hello-world/README.md buildpacks/hello-world/linux/arm64
rm buildpacks/hello-world/package.toml

cat <<EOF > buildpacks/hello-world/linux/amd64/linux-amd64.txt
This is a linux/amd64 file.
EOF

cat <<EOF > buildpacks/hello-world/linux/arm64/linux-arm64.txt
This is a linux/arm64 file..
EOF

cat <<EOF > buildpacks/hello-world/buildpack.toml
# Buildpack API version
api = "0.10"

# Buildpack ID and metadata
[buildpack]
id = "samples/hello-world"
version = "0.0.1"
name = "Hello World Buildpack"
homepage = "https://github.com/buildpacks/samples/tree/main/buildpacks/hello-world"

# Targets the buildpack will work with
[[targets]]
os = "linux"
arch = "amd64"

[[targets]]
os = "linux"
arch = "arm64"

# Stacks (deprecated) the buildpack will work with
[[stacks]]
id = "*"
EOF

comment 'After doing some changes, now the folder structure looks like this'
pe 'tree buildpacks/hello-world'
pe 'clear'
pe 'bat buildpacks/hello-world/buildpack.toml'

comment "Let's now create our multi-arch hello-world buildpack"
cd buildpacks/hello-world
pe 'clear'
pe '$PACK_BINARY buildpack package $repo/cnb-hello-world --verbose --publish'
pe 'clear'
pe 'crane manifest $repo/cnb-hello-world | jq .'
pe 'clear'


cd $SAMPLES_REPO
mkdir buildpacks/hello-moon/linux 
mv buildpacks/hello-moon/bin buildpacks/hello-moon/linux 
mv buildpacks/hello-moon/README.md buildpacks/hello-moon/linux
cat <<EOF > buildpacks/hello-moon/buildpack.toml
# Buildpack API version
api = "0.10"

# Buildpack ID and metadata
[buildpack]
id = "samples/hello-moon"
version = "0.0.1"
name = "Hello Moon Buildpack"
homepage = "https://github.com/buildpacks/samples/tree/main/buildpacks/hello-moon"
sbom-formats = ["application/vnd.cyclonedx+json"]

# Targets the buildpack will work with
[[targets]]
os = "linux"
arch = "amd64"

[[targets]]
os = "linux"
arch = "arm64"

# Stacks (deprecated) the buildpack will work with
[[stacks]]
id = "*"
EOF

cd buildpacks/hello-moon
$PACK_BINARY buildpack package $repo/cnb-hello-moon --verbose --publish
clear

cd $SAMPLES_REPO
cowsay "How do we create multi-arch composite buildpack?"
pe 'clear'

cat << EOF > buildpacks/hello-universe/package.toml
[buildpack]
uri = "."

# Targets the buildpack will work with
[[targets]]
os = "linux"
arch = "amd64"

[[targets]]
os = "linux"
arch = "arm64"

[[dependencies]]
uri = "$prefix$repo/cnb-hello-world"

[[dependencies]]
uri = "$prefix$repo/cnb-hello-moon"
EOF

comment "In this case, we need to update our package.toml file with targets"
pe 'bat buildpacks/hello-universe/package.toml'

cd buildpacks/hello-universe
pe 'clear'
pe '$PACK_BINARY buildpack package $repo/cnb-hello-universe --verbose --publish --config ./package.toml'
pe 'clear'
pe 'crane manifest $repo/cnb-hello-universe | jq .'
pe 'clear'


cd $SAMPLES_REPO

cat <<'EOF' > base-images/alpine/build/Dockerfile 
ARG base_image

FROM --platform=$BUILDPLATFORM ${base_image}

ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# Install packages that we want to make available at build time
RUN apk add --update ca-certificates git jq wget && \
  rm -rf /var/cache/apk/*

COPY ./bin/yj-$TARGETOS-$TARGETARCH-$TARGETVARIANT /usr/local/bin/yj

# Create user and group
ARG cnb_uid=1000
ARG cnb_gid=1001
RUN addgroup -g ${cnb_gid} cnb && \
  adduser -u ${cnb_uid} -G cnb -s /bin/bash -D cnb

# Set user and group
USER ${cnb_uid}:${cnb_gid}

# Set required CNB user information
ENV CNB_USER_ID=${cnb_uid}
ENV CNB_GROUP_ID=${cnb_gid}

# Set deprecated CNB stack information (see https://buildpacks.io/docs/reference/spec/migration/platform-api-0.11-0.12/#stacks-are-deprecated-1)
ARG stack_id
ENV CNB_STACK_ID=${stack_id}
EOF

# We need to copy the binaries for each platform

cp -R -f $SCRIPT_REPO/binaries/*  base-images/alpine/build/bin

cd $SAMPLES_REPO/base-images/alpine/base
docker buildx build .  --push --platform "linux/amd64,linux/arm64/v8,linux/arm/v7" --tag $repo/cnbs-base-alpine:latest  --build-arg distro_name=alpine  --build-arg distro_version=3.19.3  --build-arg stack_id=io.buildpacks.samples.stacks.alpine

cd $SAMPLES_REPO/base-images/alpine/run
docker buildx build .  --push --platform "linux/amd64,linux/arm64,linux/arm/v7" --tag $repo/cnbs-run-alpine:latest --build-arg base_image=$repo/cnbs-base-alpine:latest

cd $SAMPLES_REPO/base-images/alpine/build
docker buildx build .  --push --platform "linux/amd64,linux/arm64,linux/arm/v7" --tag $repo/cnbs-build-alpine:latest --build-arg base_image=$repo/cnbs-base-alpine:latest

clear

cd $SAMPLES_REPO

cat <<EOF >  builders/alpine/builder.toml
# Buildpacks to include in builder

[[buildpacks]]
uri = "$prefix$repo/cnb-hello-universe:latest"

[[order]]
[[order.group]]
id = "samples/hello-universe"
version = "0.0.1"

# Targets the buildpack will work with
[[targets]]
os = "linux"
arch = "amd64"

[[targets]]
os = "linux"
arch = "arm64"

# Base images used to create the builder
[build]
image = "$repo/cnbs-build-alpine:latest"
[run]
[[run.images]]
image = "$repo/cnbs-run-alpine:latest"

# Stack (deprecated) used to create the builder
[stack]
id = "io.buildpacks.samples.stacks.alpine"
build-image = "$repo/cnbs-build-alpine:latest"
run-image = "$repo/cnbs-run-alpine:latest"
EOF

cowsay "Ok! now that we have multi-arch buildpacks, builder and run images. It's time to create a multi-arch builder"
pe 'clear'

pe 'bat builders/alpine/builder.toml'
pe 'clear'

cd builders/alpine/
pe '$PACK_BINARY builder create $repo/cnbs-builder-alpine --config builder.toml --publish --verbose'
pe 'clear'
pe 'crane manifest $repo/cnbs-builder-alpine | jq .'
pe 'clear'

filter=reference=$repo/*
docker rmi -f $(docker  image ls --filter $filter -q)
docker stop $registry
docker rm $registry
clear
cat $SCRIPT_REPO/banner.txt
# echo $registry
