import { Binding, createBinding } from "@rbxts/react";
import { Animatable, Motion } from "@rbxts/ripple";

const AssignedBinding = setmetatable({}, { __tostring: () => "AssignedBinding" }) as symbol;

/**
 * Returns a React Binding that mirrors the Motion's current value.
 * The first call subscribes to motion.onChange and caches the binding
 * on the motion itself so subsequent calls return the same binding.
 */
export function getBinding<T extends Animatable>(motion: Motion<T>): Binding<T> {
	assert(motion, "Missing argument #1: motion");

	if (AssignedBinding in motion) {
		return motion[AssignedBinding as never];
	}

	const [binding, setBindingValue] = createBinding(motion.getPosition());
	motion.onChange((value) => setBindingValue(value));

	motion[AssignedBinding as never] = binding as never;
	return binding;
}

