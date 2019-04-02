FROM centos:7

ENV CLOUDSDK_CORE_DISABLE_PROMPTS 1
ENV PATH /opt/google-cloud-sdk/bin:$PATH

USER root

RUN yum -y install which wget ruby git vim bind-utils net-tools postgresql mysql telnet nc iptables tcpdump

COPY bin /usr/local/bin/
COPY src /usr/src
RUN chmod +x /usr/local/bin/*

WORKDIR /root

RUN curl https://sdk.cloud.google.com | bash && mv google-cloud-sdk /opt
RUN gcloud components install kubectl

CMD ["/usr/sbin/init"]
