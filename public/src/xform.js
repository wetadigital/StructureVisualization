//
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) Contributors to the StructureVisualization Project.
//

// Offset Records
//

class Xform {
    static offset = 1.5
    right_aligned_x;
    right_aligned_y;

    constructor (rtx, rty)
    {
        this.right_aligned_x = rtx
        this.right_aligned_y = rty
    }

    compose_right_transform ()
    {
        const rtx = this.right_aligned_x
        const rty = this.right_aligned_y
        return `translate(${rtx},${rty})`
    }

    compose_layer_transform ()
    {
        return null
    }
};

// Collapsed state doesn't need transformation, or even
// offsets. Reasoning is explained below.
class CollapsedXform extends Xform {
    bgn;
    end;

    constructor (gridX, width, unitSize, rtx, rty)
    {
        super(rtx, rty)
        const perLayerOffset = width + Xform.offset*unitSize
        const indentation = gridX*unitSize
        this.bgn = 0
        this.end = this.bgn + perLayerOffset + indentation
    }
}

// The expanded states below remove the embedded indentation
// to avoid redundant offsetting.
//

class PlanViewXform extends Xform {
    bgn;
    end;

    constructor (idx, gridX, width, stack, unitSize, rtx, rty)
    {
        super(rtx, rty)
        const perLayerOffset = width + Xform.offset*unitSize
        const indentation = gridX*unitSize
        this.bgn = stack.rel.bgn + idx*perLayerOffset - indentation
        this.end = this.bgn + perLayerOffset + indentation
    }

    compose_layer_transform ()
    {
        let xformValue = `translate(${this.bgn})`
        return xformValue
    }
}


class IsometricXform extends Xform {
    bgn;
    end;
    abs;

    constructor (idx, gridX, width, stack, unitSize, rtx, rty)
    {
        super(rtx, rty)
        const perLayerOffset = width + Xform.offset*unitSize
        const indentation = gridX*unitSize
        this.abs = stack.abs.bgn + idx * unitSize
        this.bgn = stack.rel.bgn - indentation
        this.end = this.bgn + perLayerOffset + indentation
    }

    compose_layer_transform ()
    {
        let xformValueArray = Array(3)

        // Absolute right-offsetting due to sublayers.
        xformValueArray[0] = `translate(${this.abs})`

        // matrix(a, b, c, d, e, f)
        // newX = a * oldX + c * oldY + e
        // newY = b * oldX + d * oldY + f
        //
        // a: 0.75 c: 0.   e: 0.
        // b: 0.25 d: 1.   f: 0.
        //    0.      0.      1.
        xformValueArray[1] = "matrix(0.75, 0.25, 0, 1, 0, 0)"

        // Shifting targeted arcs right in projection axis.
        xformValueArray[2] = `translate(${this.bgn})`
        return xformValueArray.join()
    }
}


class XformBundle {
    collapsed;
    plan_view;
    isometric;

    constructor (idx, gridX, width, stack, unitSize, rtx, rty)
    {
        this.collapsed = new CollapsedXform(gridX, width, unitSize, rtx, rty)
        this.plan_view = new PlanViewXform(idx, gridX, width, stack.plan_view_bounds, unitSize, rtx, rty)
        this.isometric = new IsometricXform(idx, gridX, width, stack.isometric_bounds, unitSize, rtx, rty)
    }
}

export { XformBundle }
