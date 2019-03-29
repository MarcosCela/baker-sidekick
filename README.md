# BAKER-sidekick [Bamboo Agent for KubERnetes]


![](https://img.shields.io/github/license/Markoscl/baker-sidekick.svg)
[![](https://img.shields.io/docker/pulls/markoscl/baker-sidekick.svg)](https://hub.docker.com/r/markoscl/baker-sidekick)
[![](https://img.shields.io/docker/stars/markoscl/baker-sidekick.svg)](https://hub.docker.com/r/markoscl/baker-sidekick)
[![](https://img.shields.io/docker/build/markoscl/baker-sidekick.svg)](https://hub.docker.com/r/markoscl/baker-sidekick)


# Sidekick image

[![](https://images.microbadger.com/badges/image/markoscl/baker-sidekick.svg)](https://microbadger.com/images/markoscl/baker-sidekick)

This repository contains the needed code for a sidekick image:

A sidekick image aims to provide a JDK and other needed tools to transform ANY other docker
image in a Bamboo Agent image.

## Example

Let's say that Bob wants to execute its Bamboo build in a docker image, and it is a
very simple build, so he wants to use:

    maven:3
    
As the docker image for that project. Obviously this image does not have the capability
to run a Bamboo Agent, so we have to create a way of injecting this JDK and the agent JAR and
other auxiliar scripts in the image, and change the initial running command so it
runs the agent when launched.


It sounds easy enough if we think of a ***maven*** or a ***openjdk*** or ***ubuntu*** image,
since they are fairly similar. The problem comes with really small images like ***alpine***,
since they have a different set of libraries, and OpenJDK uses dynamic linking.

Here is where the sidekick image comes into play. As an example of what this image does, we can
see the following image:

![](https://raw.githubusercontent.com/Markoscl/baker-sidekick/master/images/baker-sidekick.png)

The basic idea is to launch the "user provided agent (node in this case)", and launch
***markoscl/baker-sidekick*** together. Both images share the same volume, so the sidekick
copies files from the docker image, to the shared volume, and then exits successfully.

The entrypoint of the user provided image needs to be changed to ${shared-volume}/run-agent.jar (see details),
it will then install needed dependencies (takes 3-5 seconds), and run the agent using the shared volume
as the source for a valid JRE/JDK, agent jar and other utilities.

An example in docker compose:

```yaml
version: "3"

# This is the shared volume that both containers will use together. The same setup can be
# achieved in Kubernetes by launching sidekick and "alpine" (or other) in the same pod, using
# a shared volume
volumes:
  shared:

services:
  # The sidekick ENTRYPOINT attempts to copy the files that are needed to the shared volume. It
  # needs to be mounted in /shared, but it should be easy to change that if needed.
  sidekick:
    image:  markoscl/baker-sidekick:latest
    volumes:
      - shared:/shared
  test-agent-alpine:
  # This will be the user provided image. As you can see, it works with
  # an image that does not originally have a JRE, the agent, or even
  # the glibc base. Other images like "ubuntu", "mvn", "node" etc should
  # also work
    image: alpine
    # Change the ENTRYPOINT of the image, so it runs the run-agent.sh instead of the default image ENTRYPOINT
    # This ensures that the image gets launched (if no errors are found)
    command: ["/bin/sh","-c", "/shared/bamboo/run-agent.sh"]
    env_file:
      # You can specify environment variables for the bamboo agent etc. You will need to modify
      # run-agent.sh if you want to add more information (like bamboo token etc...)
      - common.env
    volumes:
      - shared:/shared
    depends_on:
    # This can also be done on K8s with "init containers".
      - sidekick
```


### How to test if image XXXXX is compatible?

Simply change the following files:

- [testing/common.env](testing/common.env), add here your bamboo server.
- [testing/docker-compose.yaml](testing/docker-compose.yaml), modify your image/images, and check
if the agent loads successfully. You should see "Agent xxx ready to receive builds", after the
agent has loaded correctly.



## Important notes

- Images from the user need to have at least bash, and if it is an alpine based image it needs at least
apk installed. It has been tested with alpine based images,Debian based images etc...
 (this covers a very high % of the most used images).
 
- The files get copied to the image with the user and the group "bamboo:bamboo". This ensures that
"root" (the default user for containers) can read the contents, and if you have any other user
for any reason, it can also read the files. This has not been tested enough, so some images might
have file permission problems. Please report them!


# Contribute
Feel free to contribute either with a pull request, a suggestion or something else!
 
# Docker images licenses
As with all Docker images, other software is likely to be included, which might be under other licenses,
(such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary 
software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies
 with any relevant licenses for all software contained within.