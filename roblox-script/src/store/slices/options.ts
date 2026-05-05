import { createProducer } from "@rbxts/reflex";
import { OptionsState } from "store/models/options.model";
import { persistentState } from "store/persistent-state";

const initialState: OptionsState = persistentState<OptionsState>("options", (state) => state.options, {
	currentTheme: "Sorbet",
	config: {
		acrylicBlur: true,
	},
	shortcuts: {
		toggleDashboard: Enum.KeyCode.K.Value,
	},
});

export const optionsSlice = createProducer(initialState, {
	setConfig: (state, name: keyof OptionsState["config"], active: boolean) => ({
		...state,
		config: {
			...state.config,
			[name]: active,
		},
	}),

	setTheme: (state, theme: string) => ({
		...state,
		currentTheme: theme,
	}),

	setShortcut: (state, shortcut: string, keycode: number) => ({
		...state,
		shortcuts: {
			...state.shortcuts,
			[shortcut]: keycode,
		},
	}),

	removeShortcut: (state, shortcut: string) => ({
		...state,
		shortcuts: {
			...state.shortcuts,
			[shortcut]: undefined,
		},
	}),
});
