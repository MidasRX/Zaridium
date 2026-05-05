import { useCallback, useState } from "@rbxts/react";

export function useForcedUpdate() {
	const [, setState] = useState(0);
	return useCallback(() => setState((state) => state + 1), []);
}
