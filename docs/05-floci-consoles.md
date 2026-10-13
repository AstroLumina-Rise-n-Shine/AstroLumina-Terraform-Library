# Floci web consoles: the built-in UI and the AWS-looking one

Floci ships a minimal built-in console at
`http://localhost:4566/_floci/ui`. It shows what runs in the emulator, but it
does not look like the AWS Management Console. For an AWS-console-style UI,
run **Floci Dash** next to Floci: it uses the Cloudscape Design System (the
same component library as the real AWS console) and talks to Floci over the
standard AWS API. Floci Dash is a community image, not an official Floci
release -- fine for local learning, worth knowing before trusting it with
anything else.

## Run it (verified on this machine)

Floci itself stays managed by the `floci` CLI, untouched. The dashboard runs
as a plain sibling container pointing at Floci's endpoint:

```bash
docker run -d --name floci-dash --restart unless-stopped \
  --add-host=host.docker.internal:host-gateway \
  -p 8080:3000 \
  -e FLOCI_URL='http://host.docker.internal:4566' \
  -e AWS_REGION='us-east-1' \
  -e PORT='3000' \
  ghcr.io/ofsazib/floci-dash:latest
```

Then open `http://localhost:8080`. Sign in with the emulator credentials
(`test` / `test`); the dashboard lists the same resources the AWS CLI sees
(verified: the `astrolumina-terraform-state` S3 bucket and the active
`s3` + `dynamodb` services showed up immediately).

Why a sibling container and not Floci's console-swap mechanism: Floci can
replace its `/_floci/ui` sidecar via `FLOCI_SERVICES_UI_IMAGE`, but those
variables must reach the Floci container as environment, and the `floci` CLI
(0.2.3) has no way to pass custom environment -- neither profile files nor
host-exported variables are forwarded (both tried and verified absent with
`docker inspect`). Restarting the CLI-managed container by hand just to inject
variables would also risk the in-memory emulator state. The sibling container
changes nothing about the running Floci.

## Notes

- The built-in console stays available at `:4566/_floci/ui` regardless.
- `FLOCI_URL` must be reachable from inside the dashboard container, hence
  `host.docker.internal` and not `localhost` (localhost inside the container
  is the container itself).
- `--restart unless-stopped` keeps the dashboard across laptop reboots; start
  Floci itself with `floci start` as usual.
