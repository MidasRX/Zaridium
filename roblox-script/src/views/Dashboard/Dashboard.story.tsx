import React from "@rbxts/react";
import { ReflexProvider } from "@rbxts/react-reflex";
import { createRoot } from "@rbxts/react-roblox";
import { configureStore } from "store/store";
import Dashboard from "./Dashboard";

export = (target: Frame) => {
	const store = configureStore();
	store.toggleDashboard();
	const root = createRoot(target);
	root.render(
		<ReflexProvider producer={store}>
			<Dashboard />
		</ReflexProvider>,
	);
	return () => root.unmount();
};
