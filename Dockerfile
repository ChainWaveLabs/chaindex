FROM node

FROM jenkins
USER root
COPY --from=0 /usr/local  /usr/local
RUN npm --version
RUN npm install -g truffle
RUN npm install -g ganache-cli
USER jenkins