import React from "@rbxts/react";
import { GradientTheme } from "themes/theme.interface";
import { BindingOrValue, mapBinding } from "utils/binding-util";
import { hex } from "utils/color3";
import { scale } from "utils/udim2";

interface Props extends React.PropsWithChildren {
	color?: BindingOrValue<Color3>;
	gradient?: GradientTheme;
	transparency?: BindingOrValue<number>;
	radius?: BindingOrValue<number | "circular">;
}

function Fill({ color = hex("#ffffff"), gradient, transparency = 0, radius = 0, children }: Props) {
	return (
		<frame Size={scale(1, 1)} BackgroundColor3={color} BackgroundTransparency={transparency}>
			{gradient && (
				<uigradient
					key="gradient"
					Color={gradient.color}
					Transparency={gradient.transparency}
					Rotation={gradient.rotation}
				/>
			)}

			{radius !== undefined && (
				<uicorner
					key="corner"
					CornerRadius={mapBinding(radius, (r) => (r === "circular" ? new UDim(1, 0) : new UDim(0, r)))}
				/>
			)}

			{children}
		</frame>
	);
}

export default (Fill);
