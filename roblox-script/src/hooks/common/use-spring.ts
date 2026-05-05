import { Binding, createBinding } from "@rbxts/react";
import type { Animatable, SpringOptions } from "@rbxts/ripple";

import { getBinding } from "hooks/common/flipper-hooks/get-binding";
import { useMotor } from "hooks/common/flipper-hooks/use-motor";

/**
 * Higher-level spring hook. Animates any Ripple-supported value
 * (number, Color3, UDim, UDim2, Vector2, Vector3, CFrame, Rect) toward
 * the target. When `options` is omitted the binding stays at the constant
 * value (no animation).
 */
export function useSpring<T extends Animatable>(value: T, options?: SpringOptions<T>): Binding<T> {
	if (!options) {
		return createBinding(value)[0];
	}
	const motor = useMotor(value);
	motor.spring(value as never, options);
	return getBinding(motor);
}

