---
search: false
---

# Private repositories

Fontist supports additional formulas repositories, called "private".

## Create a private repository

To create a new private repository, set up a new git repository, and place formulas there:

```sh
mkdir acme
cd acme
git init
cp ../courier_prime.yml . # from example above
git add courier_prime.yml
git commit -m "Add formula for Courier Prime"
git remote add origin git@example.com:acme/formulas.git # use your git hosting
git push origin main -u
```

## Add a private repository to Fontist

In order to find the private repository, fontist should be called with its URL or path:

```sh
fontist repo setup NAME URL
```

E.g.

```sh
fontist repo setup acme https://example.com/acme/formulas.git
# or
fontist repo setup acme git@example.com:acme/formulas.git
```

Then fonts from this repo can be installed:

```sh
fontist install "courier prime"
```

**NOTE:** A repository can be either an HTTPS or SSH Git repo. In case of SSH, a corresponding SSH key should be set up with `ssh-agent` in order to access this private repository.

## Update a private repository

If the private Fontist formula repository is updated, you can fetch the updates with the `repo update` command:

```sh
fontist repo update acme
```

If there is a need to avoid using private formulas, the repo can be removed with:

```sh
fontist repo remove acme
```

### Authentication for private formulas or private formula repositories

Authorization of private archives in private formulas can be implemented with headers.

Here is an example which works with Github releases:

```yaml
resources:
  fonts.zip:
    urls:
      - url: https://example.com/repos/acme/formulas/releases/assets/38777461
        headers:
          Accept: application/octet-stream
          Authorization: token ghp_1234567890abcdefghi
```

A token can be obtained on the [GitHub Settings > Tokens page](https://github.com/settings/tokens). This token should have at least the `repo` scope for access to these assets.
