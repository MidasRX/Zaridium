import { createProducer } from "@rbxts/reflex";
import { InferJobValue, JobsState } from "store/models/jobs.model";

const initialState: JobsState = {
	flight: { value: 60, active: false },
	walkSpeed: { value: 80, active: false },
	jumpHeight: { value: 200, active: false },

	refresh: { active: false },
	ghost: { active: false },
	godmode: { active: false },
	freecam: { active: false },

	teleport: { active: false },
	hide: { active: false },
	kill: { active: false },
	spectate: { active: false },

	rejoinServer: { active: false },
	switchServer: { active: false },
};

export const jobsSlice = createProducer(initialState, {
	setJobActive: (state, jobName: keyof JobsState, active: boolean) => ({
		...state,
		[jobName]: {
			...state[jobName],
			active,
		},
	}),

	setJobValue: <K extends keyof JobsState>(
		state: JobsState,
		jobName: K,
		value: InferJobValue<JobsState[K]>,
	) => ({
		...state,
		[jobName]: {
			...state[jobName],
			value,
		},
	}),
});
