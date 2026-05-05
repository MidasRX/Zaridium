import type { Binding } from "@rbxts/react";
import type { SpringOptions } from "@rbxts/ripple";

import { getBinding } from "hooks/common/flipper-hooks/get-binding";
import { useMotor } from "hooks/common/flipper-hooks/use-motor";

export type { SpringOptions };

export function useSpring(targetValue: number, options?: SpringOptions<number>): Binding<number> {
	const motor = useMotor(targetValue);
	motor.spring(targetValue, options);
	return getBinding(motor);
}

