import React from "@rbxts/react";
import { ReflexProvider } from "@rbxts/react-reflex";
import { createRoot } from "@rbxts/react-roblox";
import Acrylic from "components/Acrylic/Acrylic";
import { configureStore } from "store/store";
import { hex } from "utils/color3";
import { px, scale } from "utils/udim2";

export = (target: Frame) => {
	const store = configureStore();
	store.toggleDashboard();
	const root = createRoot(target);
	root.render(
		<ReflexProvider producer={store}>
			<frame
				AnchorPoint={new Vector2(0.5, 0.5)}
				Position={scale(0.3, 0.7)}
				Size={px(250, 350)}
				BackgroundColor3={hex("#000000")}
				BackgroundTransparency={0.5}
				BorderSizePixel={0}
			>
				<uicorner CornerRadius={new UDim(0, 64)} />
				<Acrylic radius={52} />
			</frame>
		</ReflexProvider>,
	);
	return () => root.unmount();
};
