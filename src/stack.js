//
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Contributors to the StructureVisualization Project.
//

import { XformBundle } from "./xform.js"

// Universal Scene Description LayerStack Representation
//

class Range {
    bgn;
    end;

    constructor (bgn, end = bgn)
    {
        this.bgn = bgn
        this.end = end
    }
}

class SingleAxisBounds {
    rel;

    constructor (rel)
    {
        this.rel = rel
    }

    required_viewport_width (widthScale)
    {
        return this.rel.end * widthScale
    }

    extend (extentEnd)
    {
        this.rel.end = extentEnd
    }
}

class DoubleAxisBounds extends SingleAxisBounds {
    abs;

    constructor (rel, abs)
    {
        super(rel)
        this.abs = abs
    }

    required_viewport_width (widthScale)
    {
        return this.abs.end + this.rel.end * widthScale
    }
}

export default class StackBounds
{
    collapsed_bounds;
    plan_view_bounds;
    isometric_bounds;

    constructor (collapsed, planView, isometric)
    {
        this.collapsed_bounds = collapsed
        this.plan_view_bounds = planView
        this.isometric_bounds = isometric
    }

    static create_root ()
    {
        const collapsed = new SingleAxisBounds(
            new Range(0)
        )
        const planView = new SingleAxisBounds(
            new Range(0)
        )
        const isometric = new DoubleAxisBounds(
            new Range(0),
            new Range(0)
        )
        return new StackBounds(collapsed, planView, isometric)
    }

    attach_new (absOffset)
    {
        const collapsed = new SingleAxisBounds(
            new Range(0)
        )

        const relBgnP = this.plan_view_bounds.rel.end
        const planView = new SingleAxisBounds(
            new Range(relBgnP)
        )

        const relBgnI = this.isometric_bounds.rel.end
        const absBgnI = this.isometric_bounds.abs.end
        const absEndI = absBgnI + absOffset
        const isometric = new DoubleAxisBounds(
            new Range(relBgnI),
            new Range(absBgnI, absEndI)
        )
        return new StackBounds(collapsed, planView, isometric)
    }
}
