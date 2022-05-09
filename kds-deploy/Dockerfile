FROM repostnetwork/deploy-utils:latest

LABEL "com.github.actions.name"="AWS KDS Deploy"
LABEL "com.github.actions.description"="Create a KDS stream and EC cluster"
LABEL "com.github.actions.icon"="cloud"
LABEL "com.github.actions.color"="red"

WORKDIR /usr/src

COPY kds-deploy.sh /kds-deploy.sh
RUN chmod +x /kds-deploy.sh
ENTRYPOINT [ "/kds-deploy.sh" ]