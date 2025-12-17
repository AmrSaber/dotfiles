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

# Make sure init.sh has no syntax errors
RUN bash -n ./init.sh

# Run init.sh in headless mode
RUN HEADLESS=1 NO_STOW=1 ./init.sh

COPY --chown=user:user . .

RUN rm -rf ~/.zshrc
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && just stow-all

WORKDIR /home/user

CMD ["zsh"]
