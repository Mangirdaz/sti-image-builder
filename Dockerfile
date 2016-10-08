FROM centos:centos7

RUN yum install -y --enablerepo=centosplus epel-release gettext wget tar automake \
      make git docker ; yum clean all
      
RUN wget https://github.com/openshift/source-to-image/releases/download/v1.1.2/source-to-image-v1.1.2-5732fdd-linux-386.tar.gz -P /tmp/ ; \
    tar -xvzf /tmp/source-to-image-v1.1.2-5732fdd-linux-386.tar.gz -C /usr/local/bin/ 

ADD bin/build.sh /buildroot/build.sh

WORKDIR /buildroot
CMD ["/buildroot/build.sh"]
