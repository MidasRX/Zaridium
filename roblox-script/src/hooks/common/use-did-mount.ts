import { useEffect, useRef } from "@rbxts/react";

export function useDidMount(callback: Callback) {
	const ref = useRef<() => void>(callback);
	useEffect(() => {
		if (ref.current) {
			ref.current();
		}
	}, []);
	return ref;
}

export function useIsMount(): boolean {
	const ref = useRef(true);
	useEffect(() => {
		ref.current = false;
	}, []);
	return ref.current;
}
