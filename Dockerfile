FROM jpetazzo/dind
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
# generate a local to suppress warnings
RUN locale-gen en_US.UTF-8

# install git and gitreceive
RUN apt-get install -yq git
RUN git clone https://github.com/gabrtv/gitreceive.git /app
RUN /app/gitreceive init

# let the git user run `sudo docker`
RUN apt-get install -yq sudo
RUN echo "%git    ALL=(ALL:ALL) NOPASSWD:/usr/local/bin/docker" >> /etc/sudoers

# install docker in docker deps
RUN apt-get install -yq aufs-tools

# install hook utilities
RUN apt-get install -yq curl vim 

# add receiver hook and entrypoint
ADD receiver /home/git/receiver
ADD entry /entry
ADD start /start

# expose an ssh daemon that runs in the foreground
ENTRYPOINT ["/entry"]
CMD ["/start"]

# install initial authorized_keys (to be managed via bind mount from host)
ADD authorized_keys /home/git/.ssh/authorized_keys
RUN chown git:git /home/git/.ssh/authorized_keys && chmod 600 /home/git/.ssh/authorized_keys
