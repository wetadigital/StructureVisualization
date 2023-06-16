//
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Contributors to the StructureVisualization Project.
//

import { XformBundle } from "./xform.js"
import { SV_CFG } from "./state.js"

// Universal Scene Description Layer Representation
//

export default class UsdLayer extends SVG.G
{
    index;
    xforms;
    get data_parent () { return this.parent().attr("data-parent") }
    get data_grid_x () { return this.parent().attr("data-gridX") }
    get data_grid_y () { return this.parent().attr("data-gridY") }
    get data_width  () { return this.parent().attr("data-width") }

    get_vis_button    = () => this.findOne("use.visibility")
    get_content_g     = () => this.findOne("g.content")
    get_right_aligned = () => this.findOne("g.right-aligned")
    get_left_aligned  = () => this.findOne("g.left-aligned")
    is_root           = () => !(this.data_parent || this.index)

    generate_xforms (stack, unitSize)
    {
        const ra = this.get_right_aligned()
        this.xforms = new XformBundle(this.index,
                                      this.data_grid_x,
                                      this.data_width,
                                      stack,
                                      unitSize,
                                      ra.transform("translateX"),
                                      ra.transform("translateY"))
    }

    constructor (node, idx)
    {
        super(node)
        this.index = idx
    }

    generate_visibility_button (visibilityButtonDef, unitSize)
    {
        const offset = 5
        const visibilityButtonX = 170
        const visibilityButtonY = this.data_grid_y*unitSize+offset
        let use = this.get_right_aligned().use(visibilityButtonDef).move(-22, offset)
        use.attr("class", "visibility")
        use.click(() => this.adjust_visibility())
    }

    modify_content_state (category, content, className, state)
    {
        const value_range = SV_CFG["visibility-range"][category][className]
        const value_state = SV_CFG["visibility"][category][`${state}`][className]
        const rootLayer = content.node.dataset.overrides
        if (className === "root-container")
        {
            const width = this.xforms[state].right_aligned_x
            this.findOne("rect.container-rect").attr("width", width)
        }

        const target_value = value_state ? value_range[1] : value_range[0]
        if (typeof(target_value) === "boolean")
        {
            if (value_state)
            {
                content.show()
            }
            else
            {
                content.hide()
            }
        }
        else if (content.opacity() !== target_value)
        {
            // console.log("Animating from %o to %o", content.opacity(), target_value)
            let runner = content.animate(250, 50, 'now').opacity(target_value)
            if (target_value == 0)
            {
                runner.after(()=>content.hide())
            }
            else
            {
                content.show()
            }
        } /*
            else
            {
            console.log("Value is already correct: %o/%o, %o",
            category,
            className,
            target_value)
            } */
    }

    animate_layer_contents (category, state)
    {
        for (const c of SV_CFG["layer-content-classes"])
        {
            const contentGroups = this.find("." + c)
            for (const cg of contentGroups)
            {
                this.modify_content_state(category, cg, c, state)
            }
        }
    }

    adjust_visibility ()
    {
        this.animate_layer_contents("eye", !this.get_content_g().visible())
    }

    switch_view_state (targetState)
    {
        const xform = this.xforms[targetState]
        const layer_transform = xform.compose_layer_transform()
        const right_transform = xform.compose_right_transform()
        this.attr("transform", layer_transform)
        this.get_right_aligned().attr("transform", right_transform)
        this.animate_layer_contents("view", targetState)
    }
}
