#!/usr/bin/env sh
# Set the bamboo server variable. The default variable is set as localhost
# debug mode for the atlas-run command (atlassian plugin development)
BAMBOO_SERVER=${BAMBOO_SERVER:-""} # Do not provide a server by default so it fails and does not try to connect to local
AGENT_NAME=${AGENT_NAME:-"Bamboo docker agent"} # Provide an agent name by default (sensible name)
AGENT_DESCRIPTION=${AGENT_DESCRIPTION:-""} # By default do not provide a description
CERT_FLAG=""
TOKEN_FLAG=""
JAVA_CMD="/shared/jdk/jre/bin/java"
# Attempt to install glibc if we are in an "alpine based" image, of just output a log if the install goes wrong:
# (maybe no apk found, maybe no file, maybe fail...)
apk add --allow-untrusted /shared/glibc.apk || echo "APK seems to not be installed"

if [ -z "${BAMBOO_TOKEN}" ]; then
    echo "Warning: agent is not using a secure token. This is not recommended!"
else
    echo "Agent is using secure token: ${BAMBOO_TOKEN}"
    TOKEN_FLAG="${BAMBOO_TOKEN}"
fi

# If the user has set the BAMBOO_IGNORE_CERT to true, then ignore certificates
if [ "${BAMBOO_IGNORE_CERT}" = true ]; then
    CERT_FLAG="-Dbamboo-agent.ignoreServerCertName=true"
    echo "Warning: agent will ignore bad certificates from server. This is not recommended!"
fi

# If the user provided a token, provide the token to the agent!
if [ -z "${BAMBOO_TOKEN}" ]; then
    echo "Warning: agent is not using a secure token. This is not recommended!"
else
    echo "Agent is using secure token: ${BAMBOO_TOKEN}"
    TOKEN_FLAG="${BAMBOO_TOKEN}"
fi
mkdir -p /shared && mkdir -p /shared/bamboo && mkdir -p /shared/bamboo/bamboo-agent-home
# For the given agent data, generate the configuration file.
# The agent will generate more data in this file (UUID, agent ID...)
cat  <<EOF > /shared/bamboo/bamboo-agent-home/bamboo-agent.cfg.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<configuration>
    <buildWorkingDirectory>/shared/bamboo/bamboo-agent-home/xml-data/build-dir</buildWorkingDirectory>
    <agentDefinition>
        <name>${AGENT_NAME}</name>
        <description>${AGENT_DESCRIPTION}</description>
    </agentDefinition>
</configuration>
EOF

# For the agent dedication, we build a base 64 encoded json object
# that serves as identification for this agent
if [ -z "${BAKER_PLANS}" ]; then
    echo "No plans selected (BAKER_PLANS is not set)"
else

    echo "Agent is set to build the following: $(echo ${BAKER_PLANS} | base64 -d)"
    echo bakerplans=${BAKER_PLANS} >> /shared/bamboo/bamboo-capabilities.properties
    echo bakerplans=${BAKER_PLANS} >> /shared/bamboo/bamboo-agent-home/bamboo-capabilities.properties
    echo bakerplanss=test >> /shared/bamboo/bamboo-agent-home/bamboo-capabilities.properties

fi
########################################################################################################################
########################################################################################################################
###################################### BOOTSTRAP AND RUN THE AGENT #####################################################
########################################################################################################################
########################################################################################################################
HOME_FLAG="-Dbamboo.home=/shared/bamboo/bamboo-agent-home"

# Declare the command that we will run (to bootstrap the agent, and then to run the agent (once bootstrapped))
bamboo_cmd="${JAVA_CMD} ${CERT_FLAG} ${HOME_FLAG} -jar /shared/bamboo/bamboo-agent.jar ${BAMBOO_SERVER}/agentServer ${TOKEN_FLAG}"

echo "Agent bootstrap and startup with: ${bamboo_cmd}"
# Run it one time to bootstrap (download dependencies), and run it a second time to start the agent (if bootstrap is OK)
${bamboo_cmd} && ${bamboo_cmd}