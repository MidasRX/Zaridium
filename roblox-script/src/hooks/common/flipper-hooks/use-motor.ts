import { useRef } from "@rbxts/react";
import { Animatable, createMotion, Motion } from "@rbxts/ripple";

/**
 * Returns a stable Ripple Motion for the given animatable initial value.
 * The Motion is created once on mount and started immediately.
 */
export function useMotor<T extends Animatable>(initialValue: T): Motion<T> {
	const ref = useRef<Motion<T>>();
	if (ref.current === undefined) {
		ref.current = createMotion(initialValue);
		ref.current.start();
	}
	return ref.current;
}

