//
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Contributors to the StructureVisualization Project.
//

class PageInfo {
    name;
    text;
    user;
    date;
    info;
    more;

    constructor(obj)
    {
        Object.assign(this, obj)
    }
}

class CategoryInfo {
    name;
    text;
    pages;

    constructor(name, text, pages)
    {
        this.name = name
        this.text = text
        this.pages = pages
    }
}

export const SV_CFG = await fetch("/res/config.json").then(r=>r.json())
export const SV_DATA = await fetch("/data/manifest.json")
    .then(response=>response.json())
    .then(data=>{
        let categories = new Map()

        for (const catKey in data)
        {
            const catSrc = data[catKey]
            let pages = new Map()

            for (const pageKey in catSrc["pages"])
            {
                pages.set(pageKey, new PageInfo(catSrc["pages"][pageKey]))
            }

            categories.set(catKey, new CategoryInfo(
                catSrc["name"],
                catSrc["text"],
                pages))
        }

        return categories
    })
