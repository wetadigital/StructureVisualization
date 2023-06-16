//
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Contributors to the StructureVisualization Project.
//

import { SV_DATA } from "./state.js"

const DEFAULT_CATEGORY = null
const DEFAULT_PAGE = null

export async function populate_page()
{
    let assignedData = false

    const buttonCatElt = document.getElementById("button-cat")
    const catListElt = document.getElementById("cat-list")
    const buttonPageElt = document.getElementById("button-page")
    const pageListElt = document.getElementById('page-list')
    const diagramElt = document.getElementById('diagram')
    const pageInfoElt = document.getElementById('page-info')
    const buttonStateElt = document.getElementById('button-state')

    const urlParams = new URLSearchParams(window.location.search)

    const catName = urlParams.has("category")
          ? urlParams.get("category")
          : DEFAULT_CATEGORY

    const pageName = urlParams.has("page")
          ? urlParams.get("page")
          : DEFAULT_PAGE

    for (const [catKey, catInfo] of SV_DATA)
    {
        const aCatElt = document.createElement("a")
        aCatElt.setAttribute("href", `?category=${catKey}`)
        aCatElt.innerText = catInfo.text
        if (catKey === catName)
        {
            // Select category.
            aCatElt.setAttribute("class", "current")
            buttonCatElt.innerText = catInfo.text

            // Populate page info based on selected category.
            for (const [pageKey, pageInfo] of catInfo.pages)
            {
                const aPageElt = document.createElement('a')
                if (pageKey === pageName)
                {
                    buttonPageElt.innerText = pageInfo.text
                    aPageElt.setAttribute("class", "current")
                    const date = new Date(pageInfo.date)
                    pageInfoElt.innerText = `Created: ${date.toDateString()}`
                    // Apply the source data to the diagram object.
                    diagramElt.setAttribute(
                        "data",
                        `/data/${catInfo.name}/${pageInfo.name}`)

                    buttonStateElt.style.display = "inline"
                    assignedData = true
                }
                aPageElt.setAttribute(
                    "href",
                    `?category=${catKey}&page=${pageKey}`)
                aPageElt.innerText = pageInfo.text

                pageListElt.appendChild(aPageElt)
            }
        }
        catListElt.appendChild(aCatElt)
    }

    if (!assignedData)
    {
        buttonStateElt.style.display = "none"
    }
}
