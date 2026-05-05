import type { Binding } from "@rbxts/react";
import type { TweenOptions } from "@rbxts/ripple";

import { getBinding } from "hooks/common/flipper-hooks/get-binding";
import { useMotor } from "hooks/common/flipper-hooks/use-motor";

export function useLinear(targetValue: number, options?: TweenOptions<number>): Binding<number> {
	const motor = useMotor(targetValue);
	motor.tween(targetValue, { easing: "linear", ...options });
	return getBinding(motor);
}

