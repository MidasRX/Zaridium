import React from "@rbxts/react";
import { BindingOrValue, mapBinding } from "utils/binding-util";
import { scale } from "utils/udim2";

interface Props extends React.PropsWithChildren {
	size?: BindingOrValue<UDim2>;
	position?: BindingOrValue<UDim2>;
	anchor?: Vector2;
	padding?: {
		top?: BindingOrValue<number>;
		right?: BindingOrValue<number>;
		bottom?: BindingOrValue<number>;
		left?: BindingOrValue<number>;
	};
	clipsDescendants?: boolean;
	zIndex?: number;
	onChange?: React.InstanceChangeEvent<Frame>;
}

function Canvas({
	size = scale(1, 1),
	position = scale(0, 0),
	anchor,
	padding,
	clipsDescendants,
	zIndex,
	onChange = {},
	children,
}: Props) {
	return (
		<frame
			Size={size}
			Position={position}
			AnchorPoint={anchor}
			ClipsDescendants={clipsDescendants}
			BackgroundTransparency={1}
			ZIndex={zIndex}
			Change={onChange}
		>
			{padding !== undefined && (
				<uipadding
					key="padding"
					PaddingTop={mapBinding(padding.top, (px) => new UDim(0, px))}
					PaddingRight={mapBinding(padding.right, (px) => new UDim(0, px))}
					PaddingBottom={mapBinding(padding.bottom, (px) => new UDim(0, px))}
					PaddingLeft={mapBinding(padding.left, (px) => new UDim(0, px))}
				/>
			)}
			{children}
		</frame>
	);
}

export default (Canvas);
