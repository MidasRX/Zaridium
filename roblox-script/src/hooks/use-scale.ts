import React from "@rbxts/react";
import { useContext } from "@rbxts/react";
import { ScaleContext } from "context/scale-context";

const [defaultScale] = React.createBinding(1);

export function useScale(): React.Binding<number> {
	return useContext(ScaleContext) ?? defaultScale;
}
