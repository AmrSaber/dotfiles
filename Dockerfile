FROM fedora:latest

RUN dnf install -y sudo && dnf clean all

# Setup user "user"
RUN useradd -m -s /bin/bash user && \
  usermod -aG wheel user && \
  echo 'Defaults !requiretty' >> /etc/sudoers && \
  echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  sed -i '/pam_loginuid/s/required/optional/' /etc/pam.d/sudo

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
