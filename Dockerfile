FROM centos/s2i-base-centos7
MAINTAINER Henry Zektser <japhar81@gmail.com>

EXPOSE 8080

ENV WILDFLY_VERSION=12.0.0.Final \
    MAVEN_VERSION=3.5.2

LABEL io.k8s.description="WildFly 12.0 with FFMpeg and ExifTools" \
      io.k8s.display-name="WildFly.12.0.0.Final.Media" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,wildfly,wildfly12,ffmpeg,exiftools" \
      io.openshift.s2i.destination="/opt/s2i/destination" \
      com.redhat.deployments-dir="/wildfly/standalone/deployments"

RUN yum install -y epel-release
RUN rpm --import http://li.nux.ro/download/nux/RPM-GPG-KEY-nux.ro
RUN yum update -y && yum upgrade -y
RUN rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm

# Install Maven, Wildfly
RUN INSTALL_PKGS="tar unzip bc which lsof java-1.8.0-openjdk java-1.8.0-openjdk-devel" && \
    yum install -y --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y && \
    (curl -v https://www.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/local/bin/mvn && \
    mkdir -p $HOME/.m2 && \
    mkdir -p /wildfly && \
    (curl -v https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar -zx --strip-components=1 -C /wildfly) && \
    mkdir -p /opt/s2i/destination

# Add s2i wildfly customizations
ADD ./contrib/wfmodules/ /wildfly/modules/
ADD ./contrib/wfbin/standalone.conf /wildfly/bin/standalone.conf
ADD ./contrib/wfcfg/standalone.xml /wildfly/standalone/configuration/standalone.xml
ADD ./contrib/settings.xml $HOME/.m2/

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

RUN chown -R 1001:0 /wildfly && chown -R 1001:0 $HOME && \
    chmod -R ug+rw /wildfly && \
    chmod -R g+rw /opt/s2i/destination

USER 1001

CMD $STI_SCRIPTS_PATH/usage
