# 02 -- Installing Floci and the AWS CLI on Linux

Floci runs local emulators of cloud APIs (currently AWS) as containers, so
Terraform can be learned and tested without spending a cent or touching a
real account. The AWS CLI is the same tool used against real AWS -- pointed
at Floci it talks to the emulator instead. Verified with Floci 0.2.3 and
aws-cli 2.37.10.

## Floci

```bash
# 1. Official install script (Linux / macOS)
curl -fsSL https://floci.io/install.sh | sh

# Alternatives: `brew install floci-io/floci/floci` (Homebrew on macOS or
# Linux), or download `floci.jar` from the floci-io/floci-cli releases
# (JVM fallback, requires Java 25+).

# 2. Verify (needs Docker: Floci itself is a CLI, the emulator runs inside
#    a container it manages)
floci --version
docker info >/dev/null && echo "docker OK"

# 3. Start the AWS emulator (pulls floci/floci:latest on first run)
floci start

# 4. Confirm it answers
floci status
```

`floci start / stop / restart / status / logs / wait` manage the container
lifecycle. `floci stop` leaves everything in place; nothing is lost except
emulator state (see `floci snapshot` to persist it). Keep the CLI itself
fresh with `floci update` (checksum-verified self-update).

## AWS CLI v2

```bash
# 1. Official installer (never apt: the distro package is v1)
curl -fsSL -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -q awscliv2.zip
sudo ./aws/install

# 2. Verify
aws --version
```

No `aws configure` needed for emulator work: Floci hands out throwaway
credentials per shell (next section).

## Pointing the AWS CLI at Floci

```bash
# Prints the four exports and nothing else -- inspect before trusting:
floci env

# Wire the current shell to the emulator:
eval "$(floci env)"
```

This sets `AWS_ENDPOINT_URL=http://localhost.floci.io:4566` (one URL for
every service), `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` to `test`,
and `AWS_DEFAULT_REGION=us-east-1`. Every `aws ...` command in that shell
now hits the emulator:

```bash
aws sts get-caller-identity
# { "UserId": "000000000000", "Account": "000000000000", ... }

aws s3api create-bucket --bucket my-first-bucket --region us-east-1
aws s3api list-buckets --query 'Buckets[].Name'
```

The wiring is per-shell and evaporates when the terminal closes -- that is
the safety property: real AWS stays unreachable unless a shell is
explicitly configured for it.

Next: [03 -- Terraform <-> Floci wiring](03-terraform-floci.md).
