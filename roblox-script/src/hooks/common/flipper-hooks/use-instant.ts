import type { Binding } from "@rbxts/react";

import { getBinding } from "hooks/common/flipper-hooks/get-binding";
import { useMotor } from "hooks/common/flipper-hooks/use-motor";

export function useInstant(targetValue: number): Binding<number> {
	const motor = useMotor(targetValue);
	motor.setPosition(targetValue);
	return getBinding(motor);
}

