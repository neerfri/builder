FROM deis/base
MAINTAINER Gabriel Monroy <gabriel@opdemand.com>

ENV DEBIAN_FRONTEND noninteractive

# upgrade base system packages
RUN apt-get update
RUN apt-get -yq upgrade

# hack for initctl not being available in Ubuntu
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# install ssh server
RUN apt-get install -yq openssh-server
RUN rm /etc/ssh/ssh_host_*
RUN dpkg-reconfigure openssh-server
RUN mkdir -p /var/run/sshd

# install docker in docker deps
RUN echo deb http://archive.ubuntu.com/ubuntu precise universe > /etc/apt/sources.list.d/universe.list
RUN echo "deb http://get.docker.io/ubuntu docker main" > /etc/apt/sources.list.d/docker.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
RUN apt-get update -q
RUN apt-get install -yq aufs-tools iptables ca-certificates lxc lxc-docker

# install hook dependencies
RUN apt-get install -yq python-pip
RUN pip install pyyaml

# install hook utilities
RUN apt-get install -yq curl vim

# install git and configure gituser
ENV GITHOME /home/git
ENV GITUSER git
RUN apt-get install -yq git
RUN useradd -d $GITHOME $GITUSER
RUN mkdir -p $GITHOME/.ssh && chown git:git $GITHOME/.ssh
RUN chown -R $GITUSER:$GITUSER $GITHOME

# let the git user run `sudo /home/git/builder` (not writeable)
RUN apt-get install -yq sudo
RUN echo "%git    ALL=(ALL:ALL) NOPASSWD:/home/git/builder" >> /etc/sudoers

# install custom confd
RUN wget -q https://s3-us-west-2.amazonaws.com/deis/confd -O /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd

# add the current build context to /app
ADD . /app
RUN chown -R root:root /app

# define the execution environment
VOLUME /var/lib/docker
ENTRYPOINT ["/app/bin/entry"]
CMD ["/app/bin/boot"]
EXPOSE 22
