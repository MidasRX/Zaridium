import { combineProducers, InferState } from "@rbxts/reflex";
import { dashboardSlice } from "./dashboard";
import { jobsSlice } from "./jobs";
import { optionsSlice } from "./options";

export type RootProducer = typeof slices & ReturnType<typeof combineProducers<typeof slices>>;
export type RootState = InferState<RootProducer>;

const slices = {
	dashboard: dashboardSlice,
	jobs: jobsSlice,
	options: optionsSlice,
};

export function configureStore(): RootProducer {
	return combineProducers(slices) as RootProducer;
}
