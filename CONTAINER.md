# Container

The [Dockerfile](Dockerfile) in this repository can be used to build and deploy a Docker image.

To build an image using `podman` (a docker alternative):

`podman build -t rpn_calculator_std .`

You have to publish port 4000 and set 2 environment variables:

- SECRET_KEY_BASE
- PHX_HOST

You can generate the first with `mix phx.gen.secret` while the second can be `localhost`.

To run the image we built before:

`podman run -d --name rpn_calculator_std --env-file=.env -p 8000:4000 localhost/rpn_calculator_std`

You can now visit [`localhost:8000`](http://localhost:8000)

# Deploy

Podman quadlets allow you to place a container under systemctl control, even rootless.

The [rpn_calculator_std.container](rpn_calculator_std.container) in this repository 
is a podman quadlet definition template.

You have to edit the reference to the image, local or remote and 
set the values of the environment variables as describe above.

This file or a link to it should then be placed in `~/.config/containers/systemd/`.
Then you use `--user` variants of `systemctl` as usual.

```
$ systemctl --user daemon-reload
$ systemctl --user start rpn_calculator_std.service
$ systemctl --user status rpn_calculator_std.service
$ systemctl --user stop rpn_calculator_std.service
```

This setup should survive system restarts.

# OCI container image management

## build image in source dir

podman build -t rpn_calculator_std .

## run in dev mode

podman run -d --name rpn_calculator_std -p 4000:4000 localhost/rpn_calculator_std

## run in production

systemctl --user status rpn_calculator_std_podman
systemctl --user restart rpn_calculator_std_podman

## tag/push on ubuntu

podman tag localhost/rpn_calculator_std:latest docker.io/svenvc/rpn_calculator_std:v6-amd64

podman push docker.io/svenvc/rpn_calculator_std:v6-amd64

## tag/push on mac

podman tag localhost/rpn_calculator_std:latest docker.io/svenvc/rpn_calculator_std:v6-arm64

podman push docker.io/svenvc/rpn_calculator_std:v6-amd64

## create/push manifest

podman manifest rm rpn_calculator_std:latest-manifest

podman manifest create rpn_calculator_std:latest-manifest

podman manifest add rpn_calculator_std:latest-manifest docker://docker.io/svenvc/rpn_calculator_std:v6-amd64

podman manifest add rpn_calculator_std:latest-manifest docker://docker.io/svenvc/rpn_calculator_std:v6-arm64

podman manifest push --all rpn_calculator_std:latest-manifest docker://docker.io/svenvc/rpn_calculator_std:v6

podman manifest push --all rpn_calculator_std:latest-manifest docker://docker.io/svenvc/rpn_calculator_std:latest
