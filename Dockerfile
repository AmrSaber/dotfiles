FROM ubuntu:latest

RUN apt-get update && apt-get install -y sudo

# Setup user "user"
RUN useradd -m -s /bin/bash user && \
  usermod -aG sudo user && \
  echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  rm -rf /var/lib/apt/lists/*

USER user
WORKDIR /home/user/.dotfiles

COPY --chown=user:user ./init.sh .
COPY --chown=user:user ./themes .

# Make sure init.sh has no syntax errors
RUN bash -n ./init.sh

# Run init.sh in headless mode
RUN HEADLESS=1 NO_STOW=1 ./init.sh

COPY --chown=user:user ./configs .
RUN rm -rf ~/.zshrc
RUN /home/linuxbrew/.linuxbrew/bin/just stow-all

WORKDIR /home/user

CMD ["zsh"]
