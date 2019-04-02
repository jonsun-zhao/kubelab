FROM centos:7

ENV CLOUDSDK_CORE_DISABLE_PROMPTS 1
ENV PATH /opt/google-cloud-sdk/bin:$PATH

USER root
RUN yum -y install which wget ruby git vim bind-utils net-tools postgresql mysql telnet nc iptables tcpdump

COPY bin /usr/local/bin/

WORKDIR /root
RUN curl https://raw.githubusercontent.com/neoseele/kubelab/master/tools/shell/k8s.sh -o k8s.sh -s
RUN curl https://sdk.cloud.google.com | bash && mv google-cloud-sdk /opt

# RUN gcloud components install kubectl
RUN gsutil cp gs://nmiu-play_tools/kubectl-114-linux /usr/local/bin/kubectl

RUN chmod +x /usr/local/bin/*

CMD ["/usr/sbin/init"]
