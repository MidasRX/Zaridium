import { useProducer, useSelector } from "@rbxts/react-reflex";
import { RootProducer, RootState } from "store/store";

/**
 * Selector hook for the Reflex root state. Drop-in replacement for the
 * old `useAppSelector` from `roact-rodux-hooked`.
 */
export function useAppSelector<Selected>(selector: (state: RootState) => Selected): Selected {
	return useSelector(selector);
}

/**
 * Returns the root producer. In Reflex, the producer is the dispatcher —
 * call its action methods directly: `producer.setJobActive("flight", true)`.
 *
 * Replaces the old `useAppDispatch` from the Rodux era.
 */
export function useAppDispatch(): RootProducer {
	return useProducer<RootProducer>();
}

/**
 * Back-compat alias. Reflex has no separate "store" — the producer is the store.
 */
export function useAppStore(): RootProducer {
	return useProducer<RootProducer>();
}
