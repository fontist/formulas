---
search: false
---

# Create a Formula

The purpose of a formula is to allow Fontist to determine where to download fonts.

There is a command that can generate a formula by an archive's link:

```sh
fontist create-formula https://quoteunquoteapps.com/courierprime/downloads/courier-prime.zip
```

The result of its execution would be a YAML file. It can be changed with a text editor.

You may need to change it manually when:

- the script could not detect proper license text
- you would like to change a name of a formula (may use the `--name` option)
- the archive is private (see [private-formula-authentication](/guide/private-repositories#private-formula-authentication))

The formula can be proposed to be merged to [the main repository](https://github.com/fontist/formulas), or added to a private repository.
