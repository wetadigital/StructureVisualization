//
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Contributors to the StructureVisualization Project.
//

import { SV_CFG } from "./state.js"
import UsdLayer from "./layer.js"
import StackBounds from "./stack.js"

const [ STATE_COLLAPSED,
        STATE_PLAN_VIEW,
        STATE_ISOMETRIC ] = SV_CFG["state-order"];
const PSEUDO_ROOT_STACK = "__ROOT__"

// Setup
//

function get_required_viewport_height(width, aspectRatio)
{
    const zoomCoefficient = width / aspectRatio[0]
    return aspectRatio[1] * zoomCoefficient
}

function set_required_width(map, key, bounds, factor)
{
    const current   = map.has(key) ? map.get(key) : 0
    const candidate = bounds.required_viewport_width(factor)
    map.set(key, Math.max(current, candidate))
}

function switch_viewport_state(state, medium, layers, widthsMap)
{
    const aspectRatio = SV_CFG["aspect-ratio"]

    // Adjust layers.
    layers.each((lyr) => lyr.switch_view_state(state))

    // Adjust viewport to fit.
    const width = widthsMap.get(state)
    if ( medium.viewbox().w != width)
    {
        let height = get_required_viewport_height(width,
                                                  aspectRatio)
        medium.animate(500, 0, 'now').viewbox(0, 0, width, height)
    }
}

export function init_diagram(diagram)
{
    var infoParaTimeout;
    const unitSize    = SV_CFG["unit-size"]
    const aspectRatio = SV_CFG["aspect-ratio"]
    const scaleFactor = SV_CFG["scale-factor"]
    const stateOrder  = SV_CFG["state-order"]

    const svgRoot = diagram.contentDocument
          .getElementById("diagram")

    if (!svgRoot)
    {
        return
    }

    const medium = SVG(svgRoot)

    // Note: Make sure an actual id is set, and not an inkscape label.
    const stacksGroup = medium.findOne("#stacks")

    const layers = new SVG.List()
    const widthsMap = new Map()
    const stackXformMap = new Map()
    stackXformMap.set(PSEUDO_ROOT_STACK, StackBounds.create_root())

    const infoPara = document.getElementById('info-para')
    medium.find("use").on(
        'mouseover',
        function(e) {
            if (infoParaTimeout)
            {
                clearTimeout(infoParaTimeout)
            }
            const sourceItem = medium.findOne(this.attr("href"))
            const info = this.node.dataset.info || sourceItem.node.dataset.info || ""
            infoPara.innerText = info
            infoParaTimeout = setTimeout(()=>{infoPara.innerText=""}, 5000)
        }
    )

    let maxLayerWidth = 0
    // Calculate offsets. In reverse order, to calculate
    // parent offsets first.
    const nofStacks = stacksGroup.children().length
    for (let riStack = nofStacks; riStack-- > 0;)
    {
        const stack = stacksGroup.children()[riStack]
        const parentStack = stack.attr("data-parent")
              || PSEUDO_ROOT_STACK
        const stackXformParent = stackXformMap.get(parentStack)
        const nofLayers = stack.children().length
        const absOffset = (nofLayers-1)*unitSize
        const stackXform = stackXformParent.attach_new(absOffset)

        for (let iLayer = 0; iLayer < nofLayers; ++iLayer)
        {
            const riLayer = nofLayers-iLayer-1
            const lyr = new UsdLayer(stack.children()[riLayer].node, iLayer)
            layers.push(lyr)
            lyr.generate_xforms(stackXform, unitSize)
            stackXform.collapsed_bounds.extend(lyr.xforms.collapsed.end + unitSize*6+8)
            stackXform.plan_view_bounds.extend(lyr.xforms.plan_view.end)
            stackXform.isometric_bounds.extend(lyr.xforms.isometric.end)
        }
        stackXformMap.set(stack.id(), stackXform)
        maxLayerWidth = Math.max(maxLayerWidth, stackXform.collapsed_bounds.rel.end)

        set_required_width(widthsMap, STATE_PLAN_VIEW,
                           stackXform.plan_view_bounds, 1)

        for (const view of [STATE_COLLAPSED, STATE_ISOMETRIC])
        {
            set_required_width(widthsMap, view,
                               stackXform.collapsed_bounds, 1)
            set_required_width(widthsMap, view,
                               stackXform.isometric_bounds, .75)
        }
    }

    for ( const l of layers )
    {
        const currentX = l.get_right_aligned().transform("translateX")
        l.xforms.collapsed.right_aligned_x = maxLayerWidth-unitSize
    }

    const initialState = document.getElementById('button-state')
          .getAttribute("data-state")

    // Calculate medium properties based on offsets.
    {
        const width = widthsMap.get(initialState)
        const height = get_required_viewport_height(width, aspectRatio)

        medium.attr("preserveAspectRatio", "xMidYMid meet")
        medium.size(scaleFactor * width,
                    scaleFactor * height)
        medium.viewbox(0, 0, width, height)
    }

    const visibilityButtonDef = medium.findOne("#visibility")
    layers.each((lyr) =>
        {
            // Instance the visibility button for every layer, disable button
            // and container.
            lyr.generate_visibility_button(visibilityButtonDef, unitSize)
            lyr.switch_view_state(initialState)
        })

    // State switching.
    //

    document.getElementById('button-state').onclick = function()
    {
        const state = this.getAttribute("data-state")
        const nofState = stateOrder.length
        const iofState = stateOrder.indexOf(state)
        const nextState = stateOrder[(iofState+1) % nofState]
        // Switch to next state.
        this.setAttribute("data-state", nextState)
        switch_viewport_state(nextState, medium,
                              layers, widthsMap)
    }
}
