#!/bin/zsh

touch private.key public.key psk.key
chmod 600 private.key public.key psk.key
wg genkey >| private.key && \
wg pubkey < private.key >| public.key && \
wg genpsk >| psk.key && \
{
  chmod 400 private.key public.key psk.key
  echo "private.key, public.key and psk.key created"
  echo
  echo "Now configure your remote wireguard server with the contents of your public.key and psk.key file"
  echo "Then configure your config.sh with the remote wireguard servers public key and the desired ip networks"
}

