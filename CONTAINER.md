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
