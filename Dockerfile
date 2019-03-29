FROM adoptopenjdk/openjdk8:alpine as jdk
# Install curl to download other dependencies
RUN apk update && apk add --no-cache curl
# Let's work in a common directory!
WORKDIR /home/bamboo
# Now download the agent JAR directly from atlassian's repository
RUN curl --fail \
    https://packages.atlassian.com/maven-closedsource-local/com/atlassian/bamboo/bamboo-agent/6.4.0/bamboo-agent-6.4.0.jar\
# The user wants to be able to use ANY image, but "alpine" based docker images do not have glibc.
# OpenJDK is compiled against glibc, so it will fail.
# To solve this problem, we install this beautiful package that allows us to run glibc compiled binaries (like "java"),
# inside an alpine based container.
# If the container is not alpine based, this step is not needed (see "run-agent.sh").
    --output "bamboo-agent.jar"
## Download glibc
RUN curl -L --fail https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.27-r0/glibc-2.27-r0.apk  --output "glibc.apk"


# Use multi-stage build to generate a really small image
FROM alpine as final
MAINTAINER github/MarcosCela
# Since this image is like a "docker volume" (its purpose is to change data from one directory to another "shared" directory),
# use a small image.
VOLUME /shared-origin /shared
COPY --from=jdk /opt/java/openjdk /shared-origin/jdk
COPY --from=jdk /home/bamboo/bamboo-agent.jar /shared-origin/bamboo/bamboo-agent.jar
COPY --from=jdk /home/bamboo/glibc.apk /shared-origin/glibc.apk
COPY scripts/run-agent.sh /shared-origin/bamboo/run-agent.sh
COPY scripts/is-ready /shared-origin/bamboo/is-ready
COPY scripts/copy.sh /copy.sh
ENTRYPOINT ["/bin/sh","/copy.sh"]
