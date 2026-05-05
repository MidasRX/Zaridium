import { createProducer } from "@rbxts/reflex";
import { DashboardPage, DashboardState } from "store/models/dashboard.model";

const initialState: DashboardState = {
	page: DashboardPage.Home,
	isOpen: false,
	hint: undefined,
	apps: {
		playerSelected: undefined,
	},
};

export const dashboardSlice = createProducer(initialState, {
	setDashboardPage: (state, page: DashboardPage) => ({
		...state,
		page,
	}),

	toggleDashboard: (state) => ({
		...state,
		isOpen: !state.isOpen,
	}),

	setHint: (state, hint: string) => ({
		...state,
		hint,
	}),

	clearHint: (state) => ({
		...state,
		hint: undefined,
	}),

	playerSelected: (state, player: Player) => ({
		...state,
		apps: {
			...state.apps,
			playerSelected: player.Name,
		},
	}),

	playerDeselected: (state) => ({
		...state,
		apps: {
			...state.apps,
			playerSelected: undefined,
		},
	}),
});
