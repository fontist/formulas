import * as YAML from "yaml"
import { readFile, readdir } from "node:fs/promises"
import { resolve, join } from "node:path"

export default {
  async paths() {
    const formulasSrcRoot = resolve(process.cwd(), "../Formulas")
    console.debug(`Using formula source root ${formulasSrcRoot}`)

    const formulas: { params: object }[] = []

    for (const item of await readdir(formulasSrcRoot, { withFileTypes: true })) {
        if (!item.isFile()) {
            console.debug(`${item.name} is not a file. Skipping.`)
        }
        console.log(`Processing ${item.name}`)

        const text = await readFile(join(formulasSrcRoot, item.name), "utf8")
        const yamls = YAML.parseAllDocuments(text).map(x => x.toJSON())
        console.log(`There are ${yamls.length} documents in ${item.name}`)

        const yaml = yamls.reduce((a, x) => Object.assign(a, x), {})
        console.log(`${item.name} has ${Object.keys(yaml).length} keys`)

        formulas.push({
            params: {
                slug: item.name.replace(/\.ya?ml$/, ""),
                yaml_url: `https://github.com/fontist/formulas/blob/v3/Formulas/${item.name}`,
                ...yaml,
            }
        })
    }

    return formulas
  }
}