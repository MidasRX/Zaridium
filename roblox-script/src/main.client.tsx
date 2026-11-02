import Make from "@rbxts/make";
import React from "@rbxts/react";
import { ReflexProvider } from "@rbxts/react-reflex";
import { createRoot } from "@rbxts/react-roblox";
import { Players } from "@rbxts/services";
import { IS_DEV } from "constants";
import { setStore } from "jobs";
import { configureStore } from "store/store";
import App from "./App";

const store = configureStore();
setStore(store);

/**
 * Mounts the app and retrieve the UI instance.
 */
async function mount() {
	const container = Make("Folder", {});
	const root = createRoot(container);
	root.render(
		<ReflexProvider producer={store}>
			<App />
		</ReflexProvider>,
	);
	// React names the root child after its key/type, not "1" like Roact did, so take whichever child appears first.
	let app = container.GetChildren()[0];
	if (!app) {
		app = container.ChildAdded.Wait()[0];
		// Resume outside the ChildAdded event: Roblox silently ignores re-parenting while the parent change is still being dispatched.
		task.wait();
	}
	return app as ScreenGui;
}

/**
 * Renders the app to the screen. Protects it if possible.
 * TODO: Roact portals are a better way to do this?
 */
function render(app: ScreenGui) {
	if (IS_DEV) {
		app.Parent = Players.LocalPlayer.WaitForChild("PlayerGui");
	} else if (gethui) {
		app.Parent = gethui();
	} else {
		app.Parent = (game as unknown as { GetService(name: string): Instance }).GetService("CoreGui");
	}
}

async function main() {
	if (getgenv && "_ORCA_IS_LOADED" in getgenv()) {
		throw "Zaridium is already loaded!";
	}

	const app = await mount();
	render(app);

	// If 3 seconds passed since the game started, show the dashboard
	if (time() > 3) {
		task.defer(() => store.toggleDashboard());
	}

	if (getgenv) {
		getgenv()._ORCA_IS_LOADED = true;
	}
}

main().catch((err) => {
	warn(`Zaridium failed to load: ${err}`);
});
