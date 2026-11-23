# Static and Variable Fonts

Google Fonts formulas carry two sources for a family that Google publishes as
a variable font. The genuine variable files, one per upright and italic
outline, come from the google/fonts repository and are listed under the
`ttf_variable` resource. The per-weight static instances, one file for each
named weight such as Thin, Medium and Black, are served by the Google Fonts
API and are listed under the `ttf_static` resource. Every style records the
resource that holds its file in a `source_resource` field, and the installer
downloads each requested style from its own resource.

```yaml
resources:
  ttf_variable:
    format: ttf
    variable_axes: [wght]
    files:
    - https://raw.githubusercontent.com/google/fonts/<sha>/ofl/worksans/WorkSans[wght].ttf
  ttf_static:
    format: ttf
    files:
    - https://fonts.gstatic.com/s/worksans/v24/QGY_z_wNahGAdqQ43RhVcIgYT2Xz5u32K-DQNigDp6_cOyA.ttf

fonts:
  - name: Work Sans Black
    styles:
      - family_name: Work Sans Black
        type: Regular
        font: WorkSans-Black.ttf
        source_font: QGY_z_wNahGAdqQ43RhVcIgYT2Xz5u32K-DQNigDp6_cOyA.ttf
        variable_font: false
        source_resource: ttf_static
  - name: Work Sans
    styles:
      - family_name: Work Sans
        type: Regular
        font: WorkSans[wght].ttf
        variable_font: true
        variable_axes: [wght]
        source_resource: ttf_variable
```

Static files are applicable for every consumer, including engines that do not
support variable fonts such as Apache FOP. For this reason the default
behavior of `fontist install` installs the static files when a formula offers
both kinds. The variable files remain available through an explicit request,
and both kinds can be installed in one call:

```sh
fontist install "Work Sans Black"        # static files (default)
fontist install "Work Sans" --variable   # variable files
fontist install "Work Sans" --both       # both kinds in one call
```

The same selection is available in the library interface:

```ruby
Fontist::Font.install("Work Sans Black", static: true)
Fontist::Font.install("Work Sans", variable: true)
Fontist::Font.install("Work Sans", both: true)
```

Manifests carry the same selection per font through the `variable` and
`all_variants` keys next to `styles`, or for all fonts at once through the
global flags of `fontist manifest install`:

```yaml
Work Sans Black:
  styles: [Regular, Italic]
  variable: false
```

```sh
fontist manifest install --static manifest.yml
fontist manifest install --both manifest.yml
```

A manifest entry that declares `variable: false` is satisfied only by a real
static file. A named instance of a variable font does not satisfy such an
entry, and the installer downloads the static file in that case.

Instancing through `--instance` produces a static instance of a variable font
at arbitrary axis values, such as `wght=350`. With the genuine static files
present in the formulas, instancing is not required for the standard weights.

Static files install under their PostScript names, for example
`WorkSans-Black.ttf`. The variable files install under their published names,
for example `WorkSans[wght].ttf`.
