import React from "@rbxts/react";

export type BindingOrValue<T> = T | React.Binding<T>;

export function isBinding(binding: unknown): binding is React.Binding<unknown> {
	return typeIs(binding, "table") && "getValue" in binding;
}

export function mapBinding<T, U>(value: BindingOrValue<T>, transform: (value: T) => U): React.Binding<U> {
	return isBinding(value) ? value.map(transform) : React.createBinding(transform(value))[0];
}

export function asBinding<T>(value: BindingOrValue<T>): React.Binding<T> {
	return isBinding(value) ? value : React.createBinding(value)[0];
}
