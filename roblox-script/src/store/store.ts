export { configureStore } from "./slices";
export type { RootProducer, RootState } from "./slices";

// Back-compat alias for legacy code that referenced RootStore (Rodux era).
// In Reflex, the producer IS the store.
export type { RootProducer as RootStore } from "./slices";
