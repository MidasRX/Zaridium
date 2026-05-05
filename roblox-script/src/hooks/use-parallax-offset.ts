import React from "@rbxts/react";
import { getBinding, useMotor } from "hooks/common/flipper-hooks";
import { useMouseLocation } from "hooks/common/use-mouse-location";
import { useViewportSize } from "hooks/common/use-viewport-size";

export function useParallaxOffset() {
	const mouseLocationMotor = useMotor(new Vector2());
	const mouseLocation = getBinding(mouseLocationMotor);
	const viewportSize = useViewportSize();

	const offset = React.joinBindings({ viewportSize, mouseLocation }).map(({ viewportSize, mouseLocation: m }) => {
		return new Vector2((m.X - viewportSize.X / 2) / viewportSize.X, (m.Y - viewportSize.Y / 2) / viewportSize.Y);
	});

	useMouseLocation((location) => {
		mouseLocationMotor.spring(location, { dampingRatio: 5 });
	});

	return offset;
}
