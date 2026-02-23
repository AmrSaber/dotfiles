FROM fedora:latest

WORKDIR /root/.dotfiles

COPY ./init.sh .

# Make sure init.sh has no syntax errors
RUN bash -n ./init.sh

# Run init.sh in headless mode
RUN HEADLESS=1 NO_STOW=1 ./init.sh

COPY . .

RUN rm -f ~/.zshrc
RUN eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && just stow-all

WORKDIR /root

CMD ["zsh"]
