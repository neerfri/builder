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

# install hook utilities
RUN apt-get install -yq curl vim

# install git and configure gitreceive
ENV GITHOME /home/git
ENV GITUSER git
RUN apt-get install -yq git
RUN useradd -d $GITHOME $GITUSER
RUN mkdir -p $GITHOME/.ssh && touch $GITHOME/.ssh/authorized_keys

# let the git user run `sudo docker`
RUN apt-get install -yq sudo
RUN echo "%git    ALL=(ALL:ALL) NOPASSWD:/usr/local/bin/docker" >> /etc/sudoers

# install docker in docker deps
RUN echo deb http://archive.ubuntu.com/ubuntu precise universe > /etc/apt/sources.list.d/universe.list && apt-get update
RUN apt-get install -yq aufs-tools iptables ca-certificates lxc

# install latest stable docker
ADD https://get.docker.io/builds/Linux/x86_64/docker-latest /usr/local/bin/docker
RUN chmod +x /usr/local/bin/docker

# install custom confd
RUN wget https://s3-us-west-2.amazonaws.com/deis/confd -O /usr/local/bin/confd
RUN chmod +x /usr/local/bin/confd

# add the current build context to /app
ADD . /app

# define the execution environment
ENTRYPOINT ["/app/bin/entry"]
CMD ["/app/bin/boot"]
EXPOSE 22
